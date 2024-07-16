import 'package:flutter/material.dart';
import 'package:vista_notes2/util/widgets.dart';
import 'package:vista_notes2/view/screen/ouathUser/loginUser.dart';
import 'package:vista_notes2/view/screen/ouathUser/signupUser.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('lib/util/images/vistalogo.png'),
          ),
          Text(
            '!سلام خیلی خوش اومدی به ویستا',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            textAlign: TextAlign.right,
            'همه چیز رو میتونی اینجا در امنیت کامل ذخیره کنی که یادت نره \n 🙂ضمنا سازنده برنامه خودش فراموشکاره',
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
          // ElevatedButton(
          //     onPressed: () {
          //       Navigator.pushNamed(context, '/login');
          //     },
          //     child: Text("child")),
          Padding(
            padding: const EdgeInsets.only(top: 290),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomButton(Colors.white, "ثبت نام", Colors.black, () {
                  Navigator.pushNamed(context, '/signup');
                }),
                CustomButton(Colors.white12, "ورود", Colors.white, () {
                  Navigator.pushNamed(context, '/login');
                }),
              ],
            ),
          )
        ],
      ),
    );
  }
}
