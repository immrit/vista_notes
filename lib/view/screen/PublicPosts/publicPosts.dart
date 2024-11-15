import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';
import '../../../provider/provider.dart';
import '../../../util/widgets.dart';
import 'AddPost.dart';

class PublicPostsScreen extends ConsumerWidget {
  PublicPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(fetchPublicPosts);
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('کافه ویستا'),
        centerTitle: true,
      ),
      endDrawer: CustomDrawer(getprofile, currentcolor, context),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(fetchPublicPosts);
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
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: post.avatarUrl.isEmpty
                                  ? AssetImage(
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
                                SizedBox(width: 1),
                                if (post.isVerified)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 16.0,
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12.0),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('متن کپی شد!')),
                                    );
                                    break;
                                  case 'delete':
                                    bool confirmDelete = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('حذف پست'),
                                        content: Text(
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
                                            child: Text('خیر'),
                                          ),
                                          TextButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.colorScheme.secondary,
                                              foregroundColor:
                                                  theme.colorScheme.onSecondary,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: Text('بله'),
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
                                        print(post.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('پست حذف شد!')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('خطا در حذف پست!')),
                                        );
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
                                  if (post.userId ==
                                      currentUserId) // فقط برای مالک
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('حذف'),
                                    ),
                                ];
                              },
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(post.content),
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
                                  // نمایش کامنت‌ها در bottom sheet
                                  _showCommentsBottomSheet(
                                      context, ref, post.id, post.userId);
                                },
                              ),
                              const SizedBox(width: 16.0),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  // تعامل به اشتراک‌گذاری
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

  void _showCommentsBottomSheet(
      BuildContext context, WidgetRef ref, String postId, String userId) {
    final GlobalKey<FlutterMentionsState> key =
        GlobalKey<FlutterMentionsState>();
    List<Map<String, dynamic>> userList = [];

    Future<void> loadUserList() async {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, username, avatar_url');

      if (response != null) {
        print("Error fetching user list: ${response}");
      } else {
        final data = response as List;
        userList = data
            .map<Map<String, dynamic>>((user) => {
                  'id': user['id'],
                  'display': user['username'],
                  'avatarUrl': user['avatar_url'] ?? '',
                })
            .toList();

        // صرفا برای دیباگ می‌توانید کاربران واکشی شده را مشاهده کنید
        print("Fetched user list: $userList");
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            loadUserList();

            final commentsAsyncValue = ref.watch(commentsProvider(postId));

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: commentsAsyncValue.when(
                        data: (comments) => comments.isEmpty
                            ? const Center(
                                child: Text('هنوز کامنتی وجود ندارد'))
                            : ListView.builder(
                                reverse: true,
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: comment.avatarUrl.isEmpty
                                          ? const AssetImage(
                                              'lib/util/images/default-avatar.jpg')
                                          : NetworkImage(comment.avatarUrl),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          comment.username,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 4),
                                        if (comment.isVerified)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.blue,
                                            size: 16.0,
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(comment.content),
                                  );
                                },
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const Center(
                          child: Text(
                              'مشکلی در بارگذاری کامنت‌ها به وجود آمده است'),
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: FlutterMentions(
                            key: key,
                            suggestionPosition: SuggestionPosition.Top,
                            decoration: InputDecoration(
                              hintText: 'کامنت خود را وارد کنید...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onMentionAdd: (mention) {
                              // مدیریت زمانی که یک منشن اضافه می‌شود
                              print('Mention added: ${mention['display']}');
                            },
                            mentions: [
                              Mention(
                                trigger: '@',
                                data: userList,
                                style: const TextStyle(color: Colors.blue),
                                matchAll: false,
                                suggestionBuilder: (data) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: data['avatarUrl']
                                              .isNotEmpty
                                          ? NetworkImage(data['avatarUrl'])
                                          : const AssetImage(
                                                  'lib/util/images/default-avatar.jpg')
                                              as ImageProvider,
                                    ),
                                    title: Text(data['display']),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final commentController =
                                key.currentState?.controller;
                            final commentText =
                                commentController?.text.trim() ?? '';
                            if (commentText.isNotEmpty) {
                              try {
                                await ref
                                    .read(commentServiceProvider)
                                    .addComment(
                                      postId: postId,
                                      content: commentText,
                                      userId: Supabase
                                          .instance.client.auth.currentUser!.id,
                                    );

                                commentController?.clear();
                                ref.invalidate(commentsProvider(postId));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('ارسال کامنت با خطا مواجه شد')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
