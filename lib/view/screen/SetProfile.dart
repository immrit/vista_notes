import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/homeScreen.dart';

import '../../main.dart';

class SetProfileData extends StatefulWidget {
  const SetProfileData({super.key});

  @override
  State<SetProfileData> createState() => _SetProfileDataState();
}

class _SetProfileDataState extends State<SetProfileData> {
  final _usernameController = TextEditingController();

  String? _avatarUrl;
  var _loading = true;

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();
      _usernameController.text = (data['username'] ?? '') as String;
    } on PostgrestException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });

    final userName = _usernameController.text.trim();
    final user = supabase.auth.currentUser;
    final updates = {
      'id': user!.id,
      'username': userName,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final response =
          await supabase.from('profiles').upsert(updates).eq('id', user.id);

      if (response.error != null) {
        String errorMessage = 'خطایی رخ داد';

        // بررسی انواع خطاها و شخصی‌سازی پیام‌ها
        if (response.error!.message.contains('duplicate key value')) {
          errorMessage =
              'این نام کاربری قبلاً انتخاب شده است. لطفاً یک نام کاربری دیگر وارد کنید.';
        } else if (response.error!.message.contains('network')) {
          errorMessage =
              'مشکلی در ارتباط با شبکه وجود دارد. لطفاً اتصال اینترنت خود را بررسی کنید.';
        } else if (response.error!.message.contains('invalid input syntax')) {
          errorMessage = 'ورودی نامعتبر است. لطفاً اطلاعات صحیح وارد کنید.';
        } else if (response.error!.message.contains('foreign key constraint')) {
          errorMessage = 'محدودیت در کلید خارجی. داده‌های مرتبط وجود ندارد.';
        } else {
          errorMessage = response.error!.message; // پیام پیش‌فرض
        }

        if (mounted) {
          context.showSnackBar(errorMessage, isError: true);
        }
      } else {
        if (mounted) {
          context.showSnackBar('پروفایل با موفقیت به‌روزرسانی شد!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        context.showSnackBar('خطای پایگاه داده: ${error.message}',
            isError: true); // شخصی‌سازی پیام برای PostgrestException
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar(
            'خطای غیرمنتظره‌ای رخ داده است. لطفاً دوباره تلاش کنید.',
            isError: true); // پیام عمومی
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'User Name'),
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    final result =
                        await _updateProfile(); // منتظر نتیجه عملیات باشید
                  },
            child: Text(_loading ? 'Saving...' : 'Update'),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
