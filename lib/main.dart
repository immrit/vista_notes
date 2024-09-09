import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/screen/homeScreen.dart';
import 'view/screen/ouathUser/loginUser.dart';
import 'view/screen/ouathUser/signupUser.dart';
import 'view/screen/ouathUser/welcome.dart';
import 'view/screen/profile.dart';
import 'view/screen/ouathUser/editeProfile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // برای حالت عمودی
  ]).then((_) async {
    await Supabase.initialize(
        url: 'https://dryadhdblerledhitmlk.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRyeWFkaGRibGVybGVkaGl0bWxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjE3NDIzMDUsImV4cCI6MjAzNzMxODMwNX0.lSpNra_VNlH8onENAOS4HEcUsJ_SREvPaoV5FBtG26g');
    runApp(const ProviderScope(child: MyApp()));
  });
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            ),
            home: supabase.auth.currentSession == null
                ? const WelcomePage()
                : const HomeScreen(),
            initialRoute: '/',
            routes: {
              '/signup': (context) => SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const Loginuser(),
              '/editeProfile': (context) => EditeProfile(),
              '/profile': (context) => const Profile(),
              '/welcome': (context) => const WelcomePage()
            },
          );
        });
  }
}
