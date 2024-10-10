import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uni_links/uni_links.dart'; // افزودن بسته uni_links
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/screen/homeScreen.dart';
import 'view/screen/ouathUser/loginUser.dart';
import 'view/screen/ouathUser/resetPassword.dart';
import 'view/screen/ouathUser/signupUser.dart';
import 'view/screen/ouathUser/welcome.dart';
import 'view/screen/profile.dart';
import 'view/screen/ouathUser/editeProfile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) async {
    await Supabase.initialize(
      url: 'https://mparmkeknhvrxqvdolph.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wYXJta2Vrbmh2cnhxdmRvbHBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYwOTU4NzIsImV4cCI6MjA0MTY3MTg3Mn0.NI2bPgfNdQJ1pd7PeYGQ6S6szyIjvcLi4HaKNogSHRY',
    );
    runApp(const ProviderScope(child: MyApp()));
  });
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  // متد برای مدیریت دیپ‌لینک‌ها
  Future<void> _handleIncomingLinks() async {
    // گوش دادن به جریان دیپ‌لینک‌ها
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == '/reset-password') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ResetPasswordPage(token: token)),
          );
        }
      }
    }, onError: (err) {
      print('خطا در دریافت دیپ‌لینک: $err');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Vista',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
            useMaterial3: true,
            fontFamily: 'Vazir',
          ),
          home: supabase.auth.currentSession == null
              ? const WelcomePage()
              : const HomeScreen(),
          initialRoute: '/',
          routes: {
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const Loginuser(),
            '/editeProfile': (context) => const EditProfile(),
            '/profile': (context) => const Profile(),
            '/welcome': (context) => const WelcomePage(),
            '/reset-password': (context) => const ResetPasswordPage(token: ''),
          },
        );
      },
    );
  }
}
