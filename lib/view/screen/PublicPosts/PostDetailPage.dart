import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../provider/provider.dart';

class PostDetailsPage extends ConsumerWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsyncValue = ref.watch(postProvider(postId));
    final commentsAsyncValue = ref.watch(commentsProvider(postId));
    final TextEditingController commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات پست'),
      ),
      body: postAsyncValue.when(
        data: (post) {
          DateTime createdAt = post.createdAt.toLocal();
          Jalali jalaliDate = Jalali.fromDateTime(createdAt);
          String formattedDate =
              '${jalaliDate.year}/${jalaliDate.month}/${jalaliDate.day}';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: post.avatarUrl.isEmpty
                                  ? const AssetImage(
                                      'assets/default_avatar.png')
                                  : NetworkImage(post.avatarUrl),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      post.username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 5),
                                    if (post.isVerified)
                                      const Icon(Icons.verified,
                                          color: Colors.blue, size: 16),
                                  ],
                                ),
                                Text(formattedDate,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(post.content,
                                style: const TextStyle(fontSize: 18))),
                        const SizedBox(height: 10),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('کامنت‌ها:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                commentsAsyncValue.when(
                  data: (comments) => comments.isEmpty
                      ? const Center(child: Text('هنوز کامنتی وجود ندارد'))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment.avatarUrl.isEmpty
                                    ? const AssetImage(
                                        'assets/default_avatar.png')
                                    : NetworkImage(comment.avatarUrl),
                              ),
                              title: Row(
                                children: [
                                  Text(comment.username),
                                  const SizedBox(width: 5),
                                  if (comment.isVerified)
                                    const Icon(Icons.verified,
                                        color: Colors.blue, size: 16),
                                ],
                              ),
                              subtitle: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(comment.content)),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('خطا در بارگذاری کامنت‌ها: $error')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('خطا در بارگذاری پست: $error')),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              labelText: 'کامنت خود را بنویسید...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  final content = commentController.text.trim();
                  if (content.isNotEmpty) {
                    try {
                      await ref.read(commentServiceProvider).addComment(
                            postId: postId,
                            content: content,
                          );
                      commentController.clear();
                      ref.refresh(commentsProvider(
                          postId)); // به‌روزرسانی لیست کامنت‌ها
                    } catch (e) {
                      print('خطا در ارسال کامنت: $e');
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
