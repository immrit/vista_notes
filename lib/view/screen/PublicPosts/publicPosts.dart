import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/model/publicPostModel.dart';
import '../../../provider/provider.dart';
import '../../../util/widgets.dart';
import 'AddPost.dart';
import 'profileScreen.dart';

class PublicPostsScreen extends ConsumerWidget {
  const PublicPostsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(themeProvider);
    final getProfile = ref.watch(profileProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'کافه ویستا',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                fontFamily: 'vazier'),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white // رنگ زیر تب انتخاب شده
                : Colors.black,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black, // رنگ متن تب انتخاب شده
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black, // رنگ متن تب‌های انتخاب نشده
            tabs: [
              const Tab(text: 'همه پست‌ها'),
              const Tab(text: 'پست‌های دنبال‌شده‌ها'),
            ],
          ),
        ),
        endDrawer: CustomDrawer(getProfile, currentColor, context, ref),
        body: const TabBarView(
          children: [
            _AllPostsTab(),
            _FollowingPostsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.edit),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddPublicPostScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AllPostsTab extends ConsumerWidget {
  const _AllPostsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(fetchPublicPosts);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(fetchPublicPosts);
      },
      child: postsAsyncValue.when(
        data: (posts) => _buildPostList(context, ref, posts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('خطا در بارگذاری پست‌ها: $err'),
        ),
      ),
    );
  }
}

class _FollowingPostsTab extends ConsumerWidget {
  const _FollowingPostsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingPostsAsyncValue = ref.watch(fetchFollowingPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(fetchFollowingPostsProvider);
      },
      child: followingPostsAsyncValue.when(
          data: (posts) => _buildPostList(context, ref, posts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            print(err);
            return Center(
              child: Text('خطا در بارگذاری پست‌های دنبال‌شده‌ها: $err'),
            );
          }),
    );
  }
}

Widget _buildPostList(
    BuildContext context, WidgetRef ref, List<PublicPostModel> posts) {
  if (posts.isEmpty) {
    return const Center(child: Text('هیچ پستی وجود ندارد.'));
  }

  return ListView.builder(
    itemCount: posts.length,
    itemBuilder: (context, index) {
      final post = posts[index];

      DateTime createdAt = post.createdAt.toLocal();
      Jalali jalaliDate = Jalali.fromDateTime(createdAt);
      String formattedDate =
          '${jalaliDate.year}/${jalaliDate.month}/${jalaliDate.day}';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: () {
                  // انتقال به صفحه پروفایل با کلیک روی عکس
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: post.userId,
                        username: post.username,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundImage: post.avatarUrl.isEmpty
                      ? const AssetImage('lib/util/images/default-avatar.jpg')
                      : NetworkImage(post.avatarUrl),
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  // انتقال به صفحه پروفایل با کلیک روی نام کاربری
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: post.userId,
                        username: post.username,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    if (post.isVerified)
                      const Icon(Icons.verified,
                          color: Colors.blue, size: 16.0),
                  ],
                ),
              ),
              subtitle: Text(
                formattedDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: _buildPostActions(context, ref, post),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: getDirectionality(post.content),
              child: Text(
                post.content,
                textAlign: getTextAlignment(post.content),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : null,
                  ),
                  onPressed: () async {
                    post.isLiked = !post.isLiked;
                    post.likeCount += post.isLiked ? 1 : -1;
                    (context as Element).markNeedsBuild();
                    await ref.watch(supabaseServiceProvider).toggleLike(
                          postId: post.id,
                          ownerId: post.userId,
                          ref: ref,
                        );
                  },
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    showCommentsBottomSheet(context, ref, post.id, post.userId);
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    String sharePost =
                        'کاربر ${post.username} به شما ارسال کرد:\n\n${post.content}';
                    Share.share(sharePost);
                  },
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      );
    },
  );
}

PopupMenuButton<String> _buildPostActions(
    BuildContext context, WidgetRef ref, PublicPostModel post) {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  return PopupMenuButton<String>(
    onSelected: (value) async {
      switch (value) {
        case 'report':
          showDialog(
            context: context,
            builder: (context) => ReportDialog(post: post),
          );
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: post.content));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('متن کپی شد!')));
          break;
        case 'delete':
          if (post.userId == currentUserId) {
            final confirmed = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('حذف پست'),
                content: const Text('آیا از حذف این پست اطمینان دارید؟'),
                actions: [
                  TextButton(
                    child: const Text('خیر'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  ElevatedButton(
                    child: const Text('بله'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.watch(supabaseServiceProvider).deletePost(ref, post.id);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('پست حذف شد!')));
            }
          }
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'report', child: Text('گزارش')),
      const PopupMenuItem(value: 'copy', child: Text('کپی')),
      if (post.userId == currentUserId)
        const PopupMenuItem(value: 'delete', child: Text('حذف')),
    ],
  );
}
