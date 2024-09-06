import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/view/screen/editeProfile.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passController.text;

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // ثبت‌نام موفقیت‌آمیز بود
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت‌نام موفقیت‌آمیز بود')),
        );
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => EditeProfile()));
      } else if (response != null) {
        // خطا در ثبت‌نام
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${response}')),
        );
      }
    } catch (error) {
      // مدیریت خطای عمومی
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('ثبت‌نام'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            topText(text: '!به ویستا خوش اومدی'),
            const SizedBox(height: 80),
            customTextField('نام کاربری', _emailController, (value) {
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
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('ثبت‌نام'),
                  ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ثبت‌نام کنید ",
                    style: TextStyle(color: Colors.blue),
                  ),
                  Text(
                    "حساب کاربری ندارید؟",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget topText({required String text}) {
  return Text(
    text,
    style: const TextStyle(color: Colors.white, fontSize: 24),
    textAlign: TextAlign.center,
  );
}

Widget customTextField(String label, TextEditingController controller,
    String? Function(String?)? validator, bool obscureText) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    validator: validator,
  );
}
