import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/main.dart';

import '../../../provider/provider.dart';

class ChangePasswordWidget extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changePasswordState =
        ref.watch(changePasswordProvider(_newPasswordController.text));

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('ویرایش رمزعبور'),
        backgroundColor: Colors.grey[900],
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.sp),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'پسورد جدید'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'تایید پسورد'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(changePasswordProvider(_newPasswordController.text)
                          .future)
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password updated successfully')),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('پسورد جدید ثبت شد')),
                    );
                  });
                }
              },
              child: Text('ویرایش رمز عبور'),
            ),
          ],
        ),
      ),
    );
  }
}
