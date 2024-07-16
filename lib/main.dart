import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista_notes2/view/screen/ouathUser/loginUser.dart';
import 'package:vista_notes2/view/screen/ouathUser/welcome.dart';

import 'view/screen/homeScreen.dart';
import 'view/screen/mainPage.dart';
import 'view/screen/ouathUser/signupUser.dart';

void main() async {
  await Supabase.initialize(
      url: 'https://hmkfgkzhyzvfeyonfoov.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhta2Zna3poeXp2ZmV5b25mb292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTgzNTgzMDAsImV4cCI6MjAzMzkzNDMwMH0.DzIrWS97erolv3ujZGstwESWL2eTZuZCpwzJh8w89X8');
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Homescreen(),
      initialRoute: '/welcome',
      routes: {
        '/signup': (context) => SignupUser(),
        '/home': (context) => Homescreen(),
        '/login': (context) => Loginuser(),
        '/main': (context) => MainPage(),
        '/welcome': (context) => WelcomePage()
      },
    );
  }
}
