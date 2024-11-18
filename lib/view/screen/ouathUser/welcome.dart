import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../util/widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(
          height: double.infinity,
          child: ListView(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).r,
                    child: Image.asset('lib/util/images/vistalogo.png'),
                  ),
                  Text(
                    '!سلام خیلی خوش اومدی به ویستا',
                    style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  // Text(
                  //   textAlign: TextAlign.right,
                  //   'همه چیز رو میتونی اینجا در امنیت کامل ذخیره کنی که یادت نره \n 🙂ضمنا سازنده برنامه خودش فراموشکاره',
                  //   style: TextStyle(fontSize: 15.sp, color: Colors.white),
                  // ),
                  SizedBox(height: 200.h),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomButtonWelcomePage(Colors.white, "ثبت نام", Colors.black,
                  () {
                Navigator.pushNamed(context, '/signup');
              }),
              CustomButtonWelcomePage(Colors.white12, "ورود", Colors.white, () {
                Navigator.pushNamed(context, '/login');
              }),
            ],
          ),
        ));
  }
}
