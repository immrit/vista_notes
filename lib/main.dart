import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista_notes2/view/screen/ouathUser/loginUser.dart';
import 'package:vista_notes2/view/screen/ouathUser/welcome.dart';
import 'package:vista_notes2/view/screen/prof.dart';

import 'view/screen/homeScreen.dart';
import 'view/screen/ouathUser/signupUser.dart';
import 'view/screen/profile.dart';

void main() async {
  await Supabase.initialize(
      url: 'https://dryadhdblerledhitmlk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRyeWFkaGRibGVybGVkaGl0bWxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjE3NDIzMDUsImV4cCI6MjAzNzMxODMwNX0.lSpNra_VNlH8onENAOS4HEcUsJ_SREvPaoV5FBtG26g');
  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vista',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: supabase.auth.currentSession == null
          ? const WelcomePage()
          : const HomeScreen(),
      initialRoute: '/',
      routes: {
        '/signup': (context) => const SignupUser(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const Loginuser(),
        '/profile': (context) => const AccountPage(),
        '/prof': (context) => ProfileScreen(),
        '/welcome': (context) => const WelcomePage()
      },
    );
  }
}
