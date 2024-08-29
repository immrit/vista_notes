import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vistaNote/main.dart';

import '../../provider/provider.dart';
import '../../util/widgets.dart';
import 'ouathUser/updatePassword.dart';

class Profile extends ConsumerWidget {
  const Profile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: getprofile.when(
        data: (getprofile) {
          return Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(
                    'lib/util/images/vistalogo.png',
                  ),
                ),
                title: Text(
                  "${getprofile!['username']}",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${supabase.auth.currentUser!.email}',
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Colors.white38,
                endIndent: 20,
                indent: 20,
              ),
              const SizedBox(height: 10),
              ProfileFields('ویرایش پروفایل', Icons.person, () {
                Navigator.pushNamed(context, '/editeProfile');
              }),
              ProfileFields('تغییر رمز عبور', Icons.lock, () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangePasswordWidget()));
              }),
              ProfileFields('حذف حساب کاربری', Icons.delete, () {}),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
