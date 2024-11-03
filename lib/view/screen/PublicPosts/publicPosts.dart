import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/view/screen/PublicPosts/AddPost.dart';
import '../../../provider/provider.dart';

class PublicPostsScreen extends ConsumerWidget {
  const PublicPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(publicPostsProvider);

    return Scaffold(
      body: postsAsyncValue.when(
        data: (posts) => RefreshIndicator(
          onRefresh: () async {
            ref.refresh(publicPostsProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(post.avatarUrl),
                    ),
                    title: Text(
                      post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(post.content),
                    trailing: Text(
                      post.createdAt.toLocal().toString().split(' ')[0],
                      style: const TextStyle(fontSize: 12.0),
                    ),
                    onTap: () {
                      // عمل مورد نظر هنگام کلیک روی پست
                    },
                  ),
                );
              },
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('دسترسی به اینترنت قطع است :('),
              IconButton(
                iconSize: 50.h,
                splashColor: Colors.transparent,
                color: Colors.white,
                onPressed: () {
                  ref.refresh(publicPostsProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.edit, color: Colors.black),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const AddPublicPostScreen()),
          );
        },
      ),
    );
  }
}
