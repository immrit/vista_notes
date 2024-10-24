import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../provider/provider.dart';
import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/ouathUser/signupUser.dart';

class Loginuser extends ConsumerWidget {
  const Loginuser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    final isLoading = ref.watch(isLoadingProvider);
    final redirecting = ref.watch(isRedirectingProvider);

    Future<void> signIn() async {
      ref.read(isLoadingProvider.notifier).state = true;

      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );
        context.showSnackBar('خوش آمدید');
        emailController.clear();
        passController.clear();
      } on AuthException {
        context.showSnackBar('نام کاربری/رمزعبور اشتباه است', isError: true);
      } catch (error) {
        context.showSnackBar('خطایی پیش آمد', isError: true);
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }

    Future<void> resetPassword() async {
      if (emailController.text.isEmpty) {
        context.showSnackBar('لطفاً ایمیل خود را وارد کنید', isError: true);
        return;
      }

      try {
        await Supabase.instance.client.auth
            .resetPasswordForEmail(emailController.text.trim());
        context.showSnackBar('ایمیل بازیابی رمز عبور ارسال شد');
      } catch (e) {
        context.showSnackBar('خطایی رخ داد، دوباره تلاش کنید', isError: true);
      }
    }

    // استفاده صحیح از ref.listen
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (next.value != null && !redirecting) {
        ref.read(isRedirectingProvider.notifier).state = true;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: ListView(
          children: [
            Column(
              children: [
                topText(
                  text: '!خوش برگشتی',
                ),
                const SizedBox(height: 80),
                customTextField('ایمیل', emailController, (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفا مقادیر را وارد نمایید';
                  }
                }, false, TextInputType.emailAddress),
                const SizedBox(height: 10),
                customTextField('رمزعبور', passController, (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفا مقادیر را وارد نمایید';
                  }
                }, true, TextInputType.visiblePassword),
                TextButton(
                  onPressed: resetPassword,
                  child: const Text(
                    'فراموشی رمز عبور؟',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()));
                        },
                        child: const Text(
                          "ثبت نام کنید ",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const Text(
                        "حساب کاربری ندارید؟",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(isLoading ? null : signIn,
            isLoading ? '...در حال ورود' : 'ورود', ref),
      ),
    );
  }
}
