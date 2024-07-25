import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista_notes2/util/widgets.dart';
import '../../../main.dart';

class Loginuser extends StatefulWidget {
  const Loginuser({Key? key}) : super(key: key);

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
        context.showSnackBar('Check your email for a login link!');

        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
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
          Navigator.pushNamed(context, '/home');
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                topText(
                  text: '!خوش برگشتی',
                ),
                const SizedBox(height: 80),
                customTextField('نام کاربری', _emailController),
                const SizedBox(height: 10),
                customTextField('رمزعبور', _passController),

//button
                const Padding(
                  padding: EdgeInsets.only(top: 360),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ثبت نام کنید ",
                        style: TextStyle(color: Colors.blue),
                      ),
                      Text(
                        "حساب کاربری ندارید؟",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 65),
                    padding: EdgeInsets.all(10),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // گردی 15 واحد
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: Text(
                    _isLoading ? 'در حال ورود...' : 'ورود',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class topText extends StatelessWidget {
  String text;
  topText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Text(
          '${text}',
          style: const TextStyle(
              fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
