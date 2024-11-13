import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // برای کپی کردن به کلیپ‌بورد
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
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
                            title: Text(
                              post.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12.0),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
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
                                  // سایر گزینه‌ها
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'report',
                                  child: Text('گزارش کردن'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'copy',
                                  child: Text('کپی کردن'),
                                ),
                                // سایر آیتم‌های منو
                              ],
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
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  // تعامل به اشتراک‌گذاری
                                  String sharePost =
                                      'کاربر ${post.username} به شما ارسال کرد: \n\n${post.content}';
                                  Share.share(sharePost);
                                },
                              ),
                              const SizedBox(width: 16.0),
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
