import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontFamily: 'Vazir'),
        title: const Text('پشتیبانی'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topCenter,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    ' تمرکز ویستا نوت علاوه بر امنیت که تاکید شدید و دائمی ما در حفظ اطلاعات کاربران بوده آسودگی کاربران از همه جهات نیز میباشد \n منتظر بازخوردهای سازنده شما هستیم :)',
                    style: TextStyle(fontFamily: 'Vazir'),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // دکمه تلگرام
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri telegramUrl = Uri.parse(
                      'https://t.me/i_mrit'); // جایگزین با آیدی تلگرام خود
                  if (await canLaunchUrl(telegramUrl)) {
                    await launchUrl(telegramUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    print('Could not launch $telegramUrl');
                  }
                },
                icon: const Icon(Icons.telegram, color: Colors.white),
                label: const Text(
                  'تماس با تلگرام',
                  style: TextStyle(color: Colors.white, fontFamily: 'Vazir'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // رنگ آبی برای دکمه تلگرام
                ),
              ),
              const SizedBox(height: 20),
              // دکمه ارسال ایمیل
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path:
                        'ahamdesmaili.official@gmail.com', // جایگزین با ایمیل خود
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri,
                        mode: LaunchMode.externalApplication);
                  } else {
                    print('Could not send email');
                  }
                },
                icon: const Icon(Icons.email, color: Colors.white),
                label: const Text('ارسال ایمیل',
                    style: TextStyle(color: Colors.white, fontFamily: 'Vazir')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // رنگ سبز برای دکمه ایمیل
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
