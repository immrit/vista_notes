// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../provider/provider.dart';
// import '../../../util/const.dart';

// class PostDetailPage extends ConsumerWidget {
//   final String postId;

//   const PostDetailPage({Key? key, required this.postId}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final postAsyncValue = ref.watch(postProvider(postId));

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('جزئیات پست'),
//       ),
//       body: postAsyncValue.when(
//         data: (post) => Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundImage: post.avatarUrl.isEmpty
//                         ? const AssetImage(defaultAvatarUrl)
//                         : NetworkImage(post.avatarUrl),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(post.username,
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(post.content, style: const TextStyle(fontSize: 16)),
//               // افزودن هر جزئیات اضافی دیگر مانند تصویر پست و غیره
//             ],
//           ),
//         ),
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) =>
//             const Center(child: Text('خطا در بارگذاری پست')),
//       ),
//     );
//   }
// }
