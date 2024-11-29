// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../model/ProfileModel.dart';
// import '../../../provider/provider.dart';

// class FollowersScreen extends ConsumerWidget {
//   final String userId;

//   const FollowersScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final followersState = ref.watch(followersProvider(userId));

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('دنبال‌کننده‌ها'),
//       ),
//       body: followersState.when(
//         data: (followers) {
//           if (followers.isEmpty) {
//             return const Center(
//               child: Text('هیچ دنبال‌کننده‌ای وجود ندارد.'),
//             );
//           }
//           return ListView.builder(
//             itemCount: followers.length,
//             itemBuilder: (context, index) {
//               final follower = followers[index];
//               return ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: follower.avatarUrl != null
//                       ? NetworkImage(follower.avatarUrl!)
//                       : const AssetImage('assets/default_avatar.png')
//                           as ImageProvider,
//                 ),
//                 title: Text(follower.username),
//                 subtitle: Text(follower.fullName ?? ''),
//                 onTap: () {
//                   Navigator.of(context).push(MaterialPageRoute(
//                     builder: (context) => ProfileScreen(
//                       userId: follower.id,
//                       username: follower.username,
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
