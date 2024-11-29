// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../model/ProfileModel.dart';
// import '../../../provider/provider.dart';

// class FollowingScreen extends ConsumerWidget {
//   final String userId;

//   const FollowingScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final followingState = ref.watch(followingProvider(userId));

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('دنبال‌شوندگان'),
//       ),
//       body: followingState.when(
//         data: (following) {
//           if (following.isEmpty) {
//             return const Center(
//               child: Text('هیچ دنبال‌شونده‌ای وجود ندارد.'),
//             );
//           }
//           return ListView.builder(
//             itemCount: following.length,
//             itemBuilder: (context, index) {
//               final followee = following[index];
//               return ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: followee.avatarUrl != null
//                       ? NetworkImage(followee.avatarUrl!)
//                       : const AssetImage('assets/default_avatar.png')
//                           as ImageProvider,
//                 ),
//                 title: Text(followee.username),
//                 subtitle: Text(followee.fullName ?? ''),
//                 onTap: () {
//                   Navigator.of(context).push(MaterialPageRoute(
//                     builder: (context) => ProfileScreen(
//                       userId: followee.id,
//                       username: followee.username,
//                     ),
//                   ));
//                 },
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, _) => Center(child: Text('خطا: $error')),
//       ),
//     );
//   }
// }
