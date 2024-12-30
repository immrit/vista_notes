import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:vistaNote/security/security.dart';
import 'package:vistaNote/view/screen/Settings.dart';
import 'firebase_options.dart';
import 'provider/provider.dart';
import 'util/themes.dart';
import 'view/screen/Notes/NotesPage.dart';
import 'view/screen/ouathUser/loginUser.dart';
import 'view/screen/ouathUser/resetPassword.dart';
import 'view/screen/ouathUser/signupUser.dart';
import 'view/screen/ouathUser/welcome.dart';
import 'view/screen/ouathUser/editeProfile.dart';

void main() async {
  await Hive.initFlutter(); // مقداردهی اولیه Hive
  await Hive.openBox('settings'); // باز کردن جعبه تنظیمات
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  updateIpAddress();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) async {
    await Supabase.initialize(
        url: 'https://mparmkeknhvrxqvdolph.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wYXJta2Vrbmh2cnhxdmRvbHBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYwOTU4NzIsImV4cCI6MjA0MTY3MTg3Mn0.NI2bPgfNdQJ1pd7PeYGQ6S6szyIjvcLi4HaKNogSHRY');

    // بازیابی تم ذخیره‌شده از Hive
    var box = Hive.box('settings');
    String savedTheme = box.get('selectedTheme', defaultValue: 'light');
    ThemeData initialTheme;

    // تنظیم تم اولیه بر اساس تم ذخیره‌شده
    switch (savedTheme) {
      case 'light':
        initialTheme = lightTheme;
        break;
      case 'dark':
        initialTheme = darkTheme;
        break;
      case 'red':
        initialTheme = redWhiteTheme;
        break;
      case 'yellow':
        initialTheme = yellowBlackTheme;
        break;
      case 'teal':
        initialTheme = tealWhiteTheme;
        break;
      default:
        initialTheme = lightTheme;
    }

    runApp(
      ProviderScope(
        overrides: [
          // Ensure themeProvider has the initial theme from Hive
          themeProvider.overrideWith((ref) => initialTheme),
        ],
        child: MyApp(initialTheme: initialTheme),
      ),
    );
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

  // Handle deep links
  void _handleIncomingLinks() {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null &&
          uri.scheme == 'vistaNote' &&
          uri.host == 'reset-password') {
        String? accessToken = uri.queryParameters['access_token'];
        if (accessToken != null) {
          Navigator.pushNamed(context, '/reset-password',
              arguments: accessToken);
        }
      }
    });
  }

  Future<void> _setFcmToken(String fcmToken) async {
    final user = supabase.auth.currentUser;
    final userId = user?.id;

    if (userId != null) {
      final username = user?.userMetadata?['username'];
    }
  }

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleIncomingLinks();

    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
          print("FcmToken: $fcmToken");
        }
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await _setFcmToken(fcmToken);
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
              title: 'Vista Notes',
              debugShowCheckedModeBanner: false,
              theme: theme, // استفاده از تم جاری
              home: supabase.auth.currentSession == null
                  ? const WelcomePage()
                  : const NotesScreen(),
              initialRoute: '/',
              routes: {
                '/signup': (context) => const SignUpScreen(),
                '/home': (context) => const NotesScreen(),
                '/login': (context) => const Loginuser(),
                '/editeProfile': (context) => const EditProfile(),
                // '/profile': (context) => const Profile(),
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
