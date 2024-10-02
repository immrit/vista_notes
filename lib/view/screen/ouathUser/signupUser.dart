import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/ouathUser/SetProfile.dart';

import '../../../main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passController = TextEditingController();
  late final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signUp() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (mounted) {
        context.showSnackBar('حساب کاربری شما با موفقیت ایجاد شد :)');

        _emailController.clear();
        _passController.clear();
        _confirmPasswordController.clear();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetProfileData()),
        );
      }
    } on AuthException catch (error) {
      // تبدیل خطاهای رایج به پیام‌های فارسی
      String errorMessage = 'خطایی رخ داد';
      if (error.message.contains('email already registered')) {
        errorMessage =
            'این ایمیل قبلاً ثبت شده است. لطفاً از ایمیل دیگری استفاده کنید.';
      } else if (error.message.contains('weak password')) {
        errorMessage =
            'رمز عبور انتخابی ضعیف است. لطفاً رمز عبور قوی‌تری وارد کنید.';
      } else if (error.message.contains('invalid email')) {
        errorMessage =
            'فرمت ایمیل وارد شده معتبر نیست. لطفاً ایمیل صحیح وارد کنید.';
      } else if (error.message.contains('network')) {
        errorMessage =
            'مشکلی در ارتباط با شبکه وجود دارد. لطفاً اتصال اینترنت خود را بررسی کنید.';
      } else if (error.message
          .contains('Password should be at least 6 characters')) {
        errorMessage = 'رمز عبور باید حداقل ۶ کاراکتر باشد.';
      } else {
        errorMessage = 'خطای نامشخصی رخ داده است. لطفاً دوباره تلاش کنید.';
      }

      if (mounted) {
        context.showSnackBar(errorMessage, isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('خطای غیرمنتظره‌ای رخ داده است.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SetProfileData()),
          );
        }
      },
      onError: (error) {
        if (error is AuthException) {
          context.showSnackBar(error.message, isError: true);
        } else {
          context.showSnackBar('Unexpected error occurred', isError: true);
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPasswordController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          topText(text: 'به ویستا خوش اومدی'),
          const SizedBox(height: 80),
          customTextField('ایمیل', _emailController, (value) {
            if (value == null || value.isEmpty) {
              return 'لطفا مقادیر را وارد نمایید';
            }
          }, false),
          const SizedBox(height: 10),
          customTextField('رمزعبور', _passController, (value) {
            if (value == null || value.isEmpty) {
              return 'لطفا مقادیر را وارد نمایید';
            }
          }, true),
          const SizedBox(height: 10),
          customTextField('تایید رمزعبور', _confirmPasswordController, (value) {
            if (value == null || value.isEmpty) {
              return 'لطفا تایید رمزعبور را وارد نمایید';
            }
            if (value != _passController.text) {
              return 'عدم تطابق رمزعبور';
            }
            return null;
          }, true),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(_isLoading ? null : _signUp,
            _isLoading ? '...در حال ورود' : 'ثبت نام'),
      ),
    );
  }
}
