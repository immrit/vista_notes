import 'package:flutter/material.dart';
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
        SizedBox(height: 50),
        Container(
            padding: EdgeInsets.only(top: 50),
            child: TextInputWidget(username, "نام کاربری", false)),
        TextInputWidget(password, "رمز عبور", true),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            child: Text("ورود",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
          ),
        )
      ],
    )));
  }
}
