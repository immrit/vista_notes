import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vista_notes/PocketBase/remoteService.dart';
import 'package:vista_notes/View/Screens/signupScreen.dart';
import 'package:vista_notes/View/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController username = TextEditingController(text: "ahmad");
  TextEditingController password = TextEditingController(text: "12345678");
  //save token
  storeToken() async {
    final prefsToken = await SharedPreferences.getInstance();
    prefsToken.setString('token', pb.authStore.token);
    // prefsToken.setString('userID', pb.authStore.model.id);
    print('Token//');
    print(pb.authStore.token);
  }

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
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              LoginUserRemote(username.text, password.text, context);
              storeToken();
            },
            child: Text("ورود",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 15),

//not account?

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
