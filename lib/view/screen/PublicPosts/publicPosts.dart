import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../provider/provider.dart';
import '../../../util/widgets.dart';
import 'AddPost.dart';
import 'profileScreen.dart';

class PublicPostsScreen extends ConsumerWidget {
  const PublicPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(fetchPublicPosts);
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'کافه ویستا',
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.bold, fontFamily: 'vazier'),
        ),
        centerTitle: true,
      ),
      endDrawer: CustomDrawer(getprofile, currentcolor, context),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(fetchPublicPosts);
          ref.refresh(profileProvider);
          ref.refresh(commentServiceProvider);
        },
        child: postsAsyncValue.when(
          data: (posts) {
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                DateTime createdAt = post.createdAt.toLocal();
                Jalali jalaliDate = Jalali.fromDateTime(createdAt);
                String formattedDate =
                    '${jalaliDate.year}/${jalaliDate.month}/${jalaliDate.day}';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                        userId: post.userId,
                                      )));
                            },
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundImage: post.avatarUrl.isEmpty
                                    ? const AssetImage(
                                        'lib/util/images/default-avatar.jpg')
                                    : NetworkImage(post.avatarUrl),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    post.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 1),
                                  if (post.isVerified)
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 16.0,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'report':
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            ReportDialog(post: post),
                                      );
                                      break;
                                    case 'copy':
                                      Clipboard.setData(
                                          ClipboardData(text: post.content));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('متن کپی شد!')));
                                      break;
                                    case 'delete':
                                      bool confirmDelete = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('حذف پست'),
                                          content: const Text(
                                              'آیا از حذف این پست اطمینان دارید؟'),
                                          actions: <Widget>[
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('خیر'),
                                            ),
                                            TextButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    theme.colorScheme.secondary,
                                                foregroundColor: theme
                                                    .colorScheme.onSecondary,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('بله'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmDelete ?? false) {
                                        final supabaseService =
                                            ref.read(supabaseServiceProvider);
                                        try {
                                          await supabaseService.deletePost(
                                              ref, post.id);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('پست حذف شد!')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('خطا در حذف پست!')));
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  final currentUserId = Supabase
                                      .instance.client.auth.currentUser?.id;
                                  return <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'report',
                                      child: Text('گزارش کردن'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'copy',
                                      child: Text('کپی کردن'),
                                    ),
                                    if (post.userId == currentUserId)
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('حذف'),
                                      ),
                                  ];
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                post.content,
                                textAlign: getTextAlignment(post.content),
                              )),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post.isLiked ? Colors.red : null,
                                ),
                                onPressed: () async {
                                  post.isLiked = !post.isLiked;
                                  post.likeCount += post.isLiked ? 1 : -1;
                                  (context as Element).markNeedsBuild();

                                  await ref
                                      .watch(supabaseServiceProvider)
                                      .toggleLike(
                                        postId: post.id,
                                        ownerId: post.userId,
                                        ref: ref,
                                      );
                                },
                              ),
                              Text('${post.likeCount}'),
                              const SizedBox(width: 16.0),
                              IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () {
                                  showCommentsBottomSheet(
                                      context, ref, post.id, post.userId);
                                },
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  String sharePost =
                                      'کاربر ${post.username} به شما ارسال کرد: \n\n${post.content}';
                                  Share.share(sharePost);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('دسترسی به اینترنت قطع است :('),
                IconButton(
                  iconSize: 50,
                  splashColor: Colors.transparent,
                  color: Colors.white,
                  onPressed: () {
                    ref.refresh(fetchPublicPosts);
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
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
    );
  }
}
