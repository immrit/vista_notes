import 'package:flutter/material.dart';
import 'package:vista_notes/View/widgets/widgets.dart';

import '../../PocketBase/remoteService.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController passwordConfirm = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        VistaTextLogo(),
        SizedBox(height: 40),
        Container(
            padding: EdgeInsets.only(top: 50),
            child: TextInputWidget(username, "نام کاربری", false)),
        TextInputWidget(email, "ایمیل", false),
        TextInputWidget(password, "رمز عبور", true),
        TextInputWidget(passwordConfirm, "تکرار رمز عبور", true),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => SignUpUserRemote(
                username.text, email.text, password.text, passwordConfirm.text),
            child: Text("عضویت",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
          ),
        ),
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
