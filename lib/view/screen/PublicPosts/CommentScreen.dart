import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/provider.dart';

class CommentsPage extends ConsumerWidget {
  final String postId;

  CommentsPage({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsyncValue = ref.watch(fetchCommentsProvider(postId));

    return Scaffold(
      appBar: AppBar(title: Text('Comments')),
      body: commentsAsyncValue.when(
        data: (comments) => ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return ListTile(
              title: Text(comment.content),
              subtitle: Text('User ID: ${comment.userId}'),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
