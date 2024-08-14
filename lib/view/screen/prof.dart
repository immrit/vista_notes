import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/main.dart';

import '../../util/widgets.dart';

class Prof extends ConsumerWidget {
  Prof({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Column(
        children: [
          const ListTile(
            leading: CircleAvatar(radius: 30),
            title: Text(
              "ahmad esmaili",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'ahmad@g.com',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 20),
          Divider(
            color: Colors.white38,
            endIndent: 20,
            indent: 20,
          ),
          const SizedBox(height: 10),
          ProfileFields('ویرایش پروفایل', Icons.person),
          ProfileFields('تغییر رمز عبور', Icons.lock),
          ProfileFields('حذف حساب کاربری', Icons.delete),
        ],
      ),
    );
  }
}
