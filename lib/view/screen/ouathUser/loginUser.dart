import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/ouathUser/signupUser.dart';
import '../../../main.dart';

class Loginuser extends StatefulWidget {
  const Loginuser({super.key});

  @override
  _LoginuserState createState() => _LoginuserState();
}

class _LoginuserState extends State<Loginuser> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (mounted) {
        context.showSnackBar('خوش آمدید');

        _emailController.clear();
        _passController.clear();
      }
    } on AuthException {
      if (mounted) {
        context.showSnackBar('نام کاربری/رمزعبور اشتباه است', isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('خطایی پیش آمد', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // متد جدید برای ارسال درخواست بازیابی رمز عبور
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      context.showSnackBar('لطفاً ایمیل خود را وارد کنید', isError: true);
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      if (mounted) {
        context.showSnackBar('ایمیل بازیابی رمز عبور ارسال شد');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('خطایی رخ داد، دوباره تلاش کنید', isError: true);
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
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        child: ListView(
          children: [
            Column(
              children: [
                topText(
                  text: '!خوش برگشتی',
                ),
                const SizedBox(height: 80),
                customTextField('ایمیل', _emailController, (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفا مقادیر را وارد نمایید';
                  }
                }, false, TextInputType.emailAddress),
                const SizedBox(height: 10),
                customTextField('رمزعبور', _passController, (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفا مقادیر را وارد نمایید';
                  }
                }, true, TextInputType.visiblePassword),

                // لینک فراموشی رمز عبور
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    'فراموشی رمز عبور؟',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()));
                        },
                        child: const Text(
                          "ثبت نام کنید ",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const Text(
                        "حساب کاربری ندارید؟",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(_isLoading ? null : _signIn,
            _isLoading ? '...در حال ورود' : 'ورود'),
      ),
    );
  }
}
