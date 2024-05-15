import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vista_notes/PocketBase/remoteService.dart';
import 'package:vista_notes/View/Screens/Home.dart';
import 'package:vista_notes/View/Screens/LoginScreen.dart';
import 'package:vista_notes/View/widgets/widgets.dart';

import '../../Model/Hive Model/userModel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var token;
  getToken() async {
    final prefsToken = await SharedPreferences.getInstance();
    token = prefsToken.getString('token');
    print('/////////////');
    print(token);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getToken();
    // Future.delayed(const Duration(seconds: 1), () {
    //   Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(builder: (context) => LoginScreen()));
    // }
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => token == null ? LoginScreen() : Home()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VistaTextLogo(),
            SpinKitThreeInOut(
              color: Colors.black,
            )
          ],
        ),
      ),
    );
  }
}
