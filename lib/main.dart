import 'package:flutter/material.dart';
import 'package:vista_notes/View/Screens/splashScreen.dart';

void main() async {
  runApp(const MyApp());
  // await Hive.initFlutter();
  // Hive.registerAdapter(UserModelAdapter());
  // await Hive.openBox<UserModel>('userBox');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vista Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
