import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ایمپورت‌های مربوط به پروژه شما
import '../../main.dart';
import '../../provider/provider.dart';
import '../../util/themes.dart';
import '../../util/widgets.dart';
import 'ouathUser/updatePassword.dart';

class Settings extends ConsumerWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
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
                      : const AssetImage('lib/util/images/default-avatar.jpg')
                          as ImageProvider,
                ),
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
            ],
          );
        },
        error: (error, stack) {
          final errorMsg = error.toString() == 'User is not logged in'
              ? 'کاربر وارد سیستم نشده است، لطفاً ورود کنید.'
              : 'خطا در دریافت اطلاعات کاربر، لطفاً دوباره تلاش کنید.';

          return Center(child: Text(errorMsg));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        height: 50,
        child: Align(
          alignment: Alignment.center,
          child: VersionNumber(),
        ),
      ),
    );
  }
}

class ThemeItems extends ConsumerWidget {
  const ThemeItems({Key? key}) : super(key: key);

  // ذخیره تم انتخاب‌شده در Hive
  void _saveThemeToHive(String theme) async {
    var box = Hive.box('settings');
    await box.put('selectedTheme', theme);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تغییر تم'),
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
              // گزینه‌های تغییر تم با آیکون و رنگ‌های متفاوت
              GestureDetector(
                onTap: () {
                  themeNotifier.state = lightTheme;
                  _saveThemeToHive('light');
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 30,
                  child: Icon(Icons.wb_sunny, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  themeNotifier.state = darkTheme;
                  _saveThemeToHive('dark');
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  radius: 30,
                  child: Icon(Icons.nightlight_round, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  themeNotifier.state = redWhiteTheme;
                  _saveThemeToHive('red');
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 30,
                  child: Icon(Icons.color_lens, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () {
                  themeNotifier.state = yellowBlackTheme;
                  _saveThemeToHive('yellow');
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  radius: 30,
                  child: Icon(Icons.color_lens, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () {
                  themeNotifier.state = tealWhiteTheme;
                  _saveThemeToHive('teal');
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.teal,
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

// ویجت قابل استفاده مجدد برای نمایش گزینه‌های تنظیمات کاربری
class ProfileFields extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ProfileFields(this.title, this.icon, this.onTap, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

// ویجت نمایش نسخه برنامه
class VersionNumber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '1.4.6+7 :نسخه', // به‌روز‌رسانی این خط با شماره نسخه فعلی برنامه
      style: const TextStyle(fontSize: 16),
    );
  }
}
