import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../provider/provider.dart';

class EditeProfile extends ConsumerWidget {
  EditeProfile({super.key});

  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofileData = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Color(Colors.grey[900]!.value),
        title: const Text('ویرایش پروفایل'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.sp),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: getprofileData.when(
        data: (data) {
          _usernameController.text = data!['username'];
          return Center(
            child: Column(
              children: [
                CircleAvatar(
                  maxRadius: .08.sh,
                  backgroundImage: const AssetImage(
                    'lib/util/images/vistalogo.png',
                  ),
                ),
                SizedBox(height: 50.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'نام کاربری',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    final updatedData = {
                      'username': _usernameController.text,
                    };
                    ref.invalidate(profileProvider);
                    ref.read(profileUpdateProvider(updatedData)).when(
                          data: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Profile updated successfully')),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to update profile: $error')),
                          ),
                        );
                  },
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}






















// class EditeProfile extends StatefulWidget {
//   const EditeProfile({super.key});

//   @override
//   State<EditeProfile> createState() => _EditeProfileState();
// }

// class _EditeProfileState extends State<EditeProfile> {
//   final _usernameController = TextEditingController();
//   final _websiteController = TextEditingController();

//   String? _avatarUrl;
//   var _loading = true;

//   /// Called once a user id is received within `onAuthenticated()`
//   Future<void> _getProfile() async {
//     setState(() {
//       _loading = true;
//     });

//     try {
//       final userId = supabase.auth.currentSession!.user.id;
//       final data =
//           await supabase.from('profiles').select().eq('id', userId).single();
//       _usernameController.text = (data['username'] ?? '') as String;
//       _websiteController.text = (data['website'] ?? '') as String;
//       _avatarUrl = (data['avatar_url'] ?? '') as String;
//     } on PostgrestException catch (error) {
//       if (mounted) context.showSnackBar(error.message, isError: true);
//     } catch (error) {
//       if (mounted) {
//         context.showSnackBar('Unexpected error occurred', isError: true);
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//     }
//   }

//   /// Called when user taps `Update` button
//   Future<void> _updateProfile() async {
//     setState(() {
//       _loading = true;
//     });
//     final userName = _usernameController.text.trim();
//     final website = _websiteController.text.trim();
//     final user = supabase.auth.currentUser;
//     final updates = {
//       'id': user!.id,
//       'username': userName,
//       'website': website,
//       'updated_at': DateTime.now().toIso8601String(),
//     };
//     try {
//       await supabase.from('profiles').upsert(updates);
//       if (mounted) context.showSnackBar('Successfully updated profile!');
//     } on PostgrestException catch (error) {
//       if (mounted) context.showSnackBar(error.message, isError: true);
//     } catch (error) {
//       if (mounted) {
//         context.showSnackBar('Unexpected error occurred', isError: true);
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//     }
//   }

//   Future<void> _signOut() async {
//     try {
//       await supabase.auth.signOut();
//     } on AuthException catch (error) {
//       if (mounted) context.showSnackBar(error.message, isError: true);
//     } catch (error) {
//       if (mounted) {
//         context.showSnackBar('Unexpected error occurred', isError: true);
//       }
//     } finally {
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const WelcomePage()),
//         );
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _getProfile();
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _websiteController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(onPressed: () => _signOut, icon: const Icon(Icons.logout))
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
//         children: [
//           TextFormField(
//             controller: _usernameController,
//             style: const TextStyle(color: Colors.black),
//             decoration: const InputDecoration(labelText: 'User Name'),
//           ),
//           const SizedBox(height: 18),
//           TextFormField(
//             controller: _websiteController,
//             style: const TextStyle(color: Colors.black),
//             decoration: const InputDecoration(labelText: 'Website'),
//           ),
//           const SizedBox(height: 18),
//           ElevatedButton(
//             onPressed: _loading ? null : _updateProfile,
//             child: Text(_loading ? 'Saving...' : 'Update'),
//           ),
//           const SizedBox(height: 18),
//         ],
//       ),
//     );
//   }
// }
