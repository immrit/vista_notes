import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/util/widgets.dart';

import '../../../provider/provider.dart';

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
          return Center(
              child: Column(children: [
            CircleAvatar(
              maxRadius: .08.sh,
              backgroundImage: const AssetImage(
                'lib/util/images/vistalogo.png',
              ),
            ),
            SizedBox(height: 50.h),
            customTextField('نام کاربری', _usernameController, (value) {
              if (value == null || value.isEmpty) {
                return 'لطفا مقادیر را وارد نمایید';
              }
            }, false)
          ]));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(() {
          final updatedData = {
            'username': _usernameController.text,
          };
          ref.refresh(profileProvider);
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نام شما با موفقیت تغییر کرد')),
          );
          ref.read(profileUpdateProvider(updatedData)).when(
                data: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                  // هدایت به صفحه اصلی بعد از ویرایش نام کاربری

                  Navigator.pushReplacementNamed(context, '/home');
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $error')),
                ),
              );
        }, 'ذخیره'),
      ),
    );
  }
}
