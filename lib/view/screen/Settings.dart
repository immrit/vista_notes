import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vistaNote/main.dart';

import '../../provider/provider.dart';
import '../../util/themes.dart';
import '../../util/widgets.dart';
import 'ouathUser/updatePassword.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنظیمات',
        ),
      ),
      body: getprofile.when(
        data: (getprofile) {
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: getprofile!['avatar_url'] != null
                        ? NetworkImage(getprofile['avatar_url'].toString())
                        : const AssetImage(
                            'lib/util/images/default-avatar.jpg')),
                title: Text(
                  "${getprofile['username']}",
                ),
                subtitle: Text(
                  '${supabase.auth.currentUser!.email}',
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                endIndent: 20,
                indent: 20,
              ),
              const SizedBox(height: 10),
              ProfileFields('ویرایش پروفایل', Icons.person, () {
                Navigator.pushNamed(context, '/editeProfile');
              }),
              ProfileFields('تغییر رمز عبور', Icons.lock, () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangePasswordWidget()));
              }),
              ProfileFields('تم و استایل', Icons.color_lens, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ThemeItems()));
              }),
              // ProfileFields('حذف حساب کاربری', Icons.delete, () {}),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ThemeItems extends ConsumerWidget {
  const ThemeItems({super.key});

  // تابع برای ذخیره تم انتخاب شده در Hive
  void _saveThemeToHive(String theme) async {
    var box = Hive.box('settings');
    box.put('selectedTheme', theme); // ذخیره تم در Hive
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier =
        ref.watch(themeProvider.notifier); // دسترسی به notifier تم

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Theme'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 10, bottom: 15),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "استایل ها:",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // دکمه گرد برای تم روشن
              GestureDetector(
                onTap: () {
                  themeNotifier.state = lightTheme; // تغییر به تم روشن
                  _saveThemeToHive('light'); // ذخیره تم در Hive
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.blue, // رنگ دکمه: آبی برای تم روشن
                  radius: 30,
                  child: Icon(Icons.wb_sunny, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // دکمه گرد برای تم تاریک
              GestureDetector(
                onTap: () {
                  themeNotifier.state = darkTheme; // تغییر به تم تاریک
                  _saveThemeToHive('dark'); // ذخیره تم در Hive
                },
                child: const CircleAvatar(
                  backgroundColor:
                      Colors.blueGrey, // رنگ دکمه: خاکستری برای تم تاریک
                  radius: 30,
                  child: Icon(Icons.nightlight_round, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // دکمه گرد برای تم سفارشی
              GestureDetector(
                onTap: () {
                  themeNotifier.state = customTheme; // تغییر به تم سفارشی
                  _saveThemeToHive('custom'); // ذخیره تم در Hive
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.red, // رنگ دکمه: قرمز برای تم سفارشی
                  radius: 30,
                  child: Icon(Icons.color_lens, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
