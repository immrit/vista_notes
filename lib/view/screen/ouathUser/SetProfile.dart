import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/homeScreen.dart';

import '../../../main.dart';

class SetProfileData extends StatefulWidget {
  const SetProfileData({super.key});

  @override
  State<SetProfileData> createState() => _SetProfileDataState();
}

class _SetProfileDataState extends State<SetProfileData> {
  final _usernameController = TextEditingController();
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
      if (mounted) {
        context.showSnackBar('خطا در بازیابی پروفایل: ${error.message}',
            isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('خطای غیرمنتظره‌ای رخ داد.', isError: true);
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
      'email': user.email
    };
    try {
      await supabase.from('profiles').upsert(updates);
      if (mounted) {
        context.showSnackBar('پروفایل با موفقیت به‌روزرسانی شد!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on PostgrestException catch (error) {
      String errorMessage = 'خطا در بروزرسانی پروفایل: ${error.message}';

      // شخصی‌سازی پیام‌های خطا
      if (error.message.contains('duplicate key value')) {
        errorMessage =
            'این نام کاربری قبلاً استفاده شده است. لطفاً یک نام کاربری دیگر وارد کنید.';
      } else if (error.message.contains('network')) {
        errorMessage =
            'مشکلی در ارتباط با شبکه رخ داده است. لطفاً اتصال خود را بررسی کنید.';
      } else if (error.message.contains('invalid input syntax')) {
        errorMessage = 'ورودی نامعتبر است. لطفاً اطلاعات صحیح وارد کنید.';
      }

      if (mounted) {
        context.showSnackBar(errorMessage, isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar(
            'خطای غیرمنتظره‌ای رخ داد. لطفاً دوباره تلاش کنید.',
            isError: true);
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('نام کاربری خود را مشخص کنید'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          customTextField('نام کاربری', _usernameController, (value) {
            if (value == null || value.isEmpty) {
              return 'لطفا مقادیر را وارد نمایید';
            }
          }, false),
          const SizedBox(height: 18),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(_loading ? null : _updateProfile,
            _loading ? 'در حال ذخیره‌سازی...' : 'ذخیره'),
      ),
    );
  }
}
