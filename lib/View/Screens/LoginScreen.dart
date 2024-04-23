import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vista_notes/View/Screens/signupScreen.dart';
import 'package:vista_notes/View/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        VistaTextLogo(),
        const SizedBox(height: 50),
        Container(
            padding: const EdgeInsets.only(top: 50),
            child: TextInputWidget(username, "نام کاربری", false)),
        TextInputWidget(password, "رمز عبور", true),
        LoginAndSignUpButton(),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextButton(onPressed: () {}, child: Text("ثبت نام")),
            GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const SignUpScreen()));
                },
                child: const Text(
                  "ثبت نام ",
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )),
            const Text(
              "حساب کاربری ندارید؟",
              style: TextStyle(fontSize: 15),
            ),
          ],
        )
      ],
    )));
  }
}
