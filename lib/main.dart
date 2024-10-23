import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:vistaNote/view/screen/Settings.dart';
import 'provider/provider.dart';
import 'util/themes.dart';
import 'view/screen/homeScreen.dart';
import 'view/screen/ouathUser/loginUser.dart';
import 'view/screen/ouathUser/resetPassword.dart';
import 'view/screen/ouathUser/signupUser.dart';
import 'view/screen/ouathUser/welcome.dart';
import 'view/screen/profile.dart';
import 'view/screen/ouathUser/editeProfile.dart';

void main() async {
  await Hive.initFlutter(); // مقداردهی اولیه Hive
  await Hive.openBox('settings'); // باز کردن جعبه تنظیمات

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) async {
    await Supabase.initialize(
      url: 'https://mparmkeknhvrxqvdolph.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wYXJta2Vrbmh2cnhxdmRvbHBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYwOTU4NzIsImV4cCI6MjA0MTY3MTg3Mn0.NI2bPgfNdQJ1pd7PeYGQ6S6szyIjvcLi4HaKNogSHRY',
    );

    // بازیابی تم ذخیره‌شده از Hive
    var box = Hive.box('settings');
    String savedTheme = box.get('selectedTheme', defaultValue: 'light');
    ThemeData initialTheme;

    // تنظیم تم اولیه بر اساس تم ذخیره‌شده
    switch (savedTheme) {
      case 'dark':
        initialTheme = darkTheme;
        break;
      case 'custom':
        initialTheme = customTheme;
        break;
      default:
        initialTheme = lightTheme;
    }

    runApp(ProviderScope(child: MyApp(initialTheme: initialTheme)));
  });
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerStatefulWidget {
  // تغییر به ConsumerStatefulWidget
  final ThemeData initialTheme;

  const MyApp({super.key, required this.initialTheme});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription? _sub;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks(); // ایجاد یک instance از AppLinks
    _handleIncomingLinks(); // هندل کردن دیپ لینک‌ها

    // تنظیم تم اولیه از Hive
    final themeNotifier = ref.read(themeProvider.notifier);
    themeNotifier.state = widget.initialTheme;
  }

  // مدیریت دیپ لینک‌ها
  void _handleIncomingLinks() {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null &&
          uri.scheme == 'vistaNote' &&
          uri.host == 'reset-password') {
        String? accessToken = uri.queryParameters['access_token'];
        if (accessToken != null) {
          // هدایت به صفحه بازیابی رمز عبور با توکن
          Navigator.pushNamed(context, '/reset-password',
              arguments: accessToken);
        }
      }
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
        return Consumer(
          builder: (context, ref, child) {
            final theme =
                ref.watch(themeProvider); // دریافت تم جاری از طریق Riverpod
            return MaterialApp(
              title: 'Vista',
              debugShowCheckedModeBanner: false,
              theme: theme, // استفاده از تم جاری
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
                '/settings': (context) => const Settings(),
                '/reset-password': (context) => ResetPasswordPage(
                      token:
                          ModalRoute.of(context)?.settings.arguments as String,
                    ),
              },
            );
          },
        );
      },
    );
  }
}
