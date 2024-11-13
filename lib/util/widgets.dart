import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';
import 'package:vistaNote/model/NotesModel.dart';
import 'package:vistaNote/view/screen/Notes/AddNoteScreen.dart';
import '../model/notificationModel.dart';
import '../model/publicPostModel.dart';
import '../provider/provider.dart';
import '../view/screen/searchPage.dart';
import '../view/screen/support.dart';
import 'themes.dart';

Text VersionNumber() {
  //ورژن یکی عقبه
  return const Text('نسخه: 1.4.5+6');
}

class topText extends StatelessWidget {
  String text;
  topText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Text(
          text,
          style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

Widget CustomButtonWelcomePage(
    Color backgrundColor, String text, Color colorText, dynamic click) {
  return GestureDetector(
    onTap: click,
    child: Container(
      width: 180,
      height: 65,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), color: backgrundColor),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              color: colorText, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(textDirection: TextDirection.rtl, message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}

Widget customTextField(String hintText, TextEditingController controller,
    dynamic validator, bool obscureText, TextInputType keyboardType) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: .7,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ),
  );
}

Widget customButton(dynamic ontap, String text, final WidgetRef ref) {
  final currentTheme = ref.watch(themeProvider); // دریافت تم جاری

  return GestureDetector(
    onTap: ontap,
    child: Container(
      width: 350,
      height: 50,
      decoration: BoxDecoration(
          color: currentTheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(15)),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: TextStyle(
            fontSize: 20,
            color: currentTheme.brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget ProfileFields(String name, IconData icon, dynamic onclick) {
  return GestureDetector(
    onTap: onclick,
    child: Column(
      children: [
        SizedBox(
            width: double.infinity,
            height: 45,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  icon,
                ),
                title: Text(
                  name,
                ),
              ),
            )),
        const Divider(indent: 0, endIndent: 59),
      ],
    ),
  );
}

Widget addNotesTextFiels(
    String name,
    int lines,
    TextEditingController controller,
    double fontSize,
    FontWeight fontWeight,
    param5,
    {int? maxLength}) {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        maxLines: lines,
        maxLength: maxLength,
        controller: controller,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        scrollPhysics: const NeverScrollableScrollPhysics(),
        decoration: InputDecoration(
            hintText: name,
            border: InputBorder.none,
            hintStyle: TextStyle(fontSize: 25.sp)),
      ),
    ),
  );
}

//bottomSheet
void showCustomBottomSheet(
    BuildContext context, Note note, Function ontapFunction) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('ویرایش'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddNoteScreen(note: note)));
              },
            ),
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? Colors.orange : Colors.grey,
              ),
              title: Text(note.isPinned ? 'برداشتن پین' : 'پین کردن'),
              onTap: () async {
                Navigator.pop(context); // بستن BottomSheet

                // تغییر وضعیت پین در مدل
                final updatedNote = note.copyWith(isPinned: !note.isPinned);

                // بررسی وجود یادداشت در پایگاه داده
                final response =
                    await supabase.from('Notes').select().eq('id', note.id);

                if (response.isEmpty) {
                  print('Note not found in database');
                  return;
                }

                // به‌روزرسانی وضعیت پین در Supabase
                final updateResponse = await supabase.from('Notes').update(
                    {'is_pinned': updatedNote.isPinned}).eq('id', note.id);

                if (updateResponse.error != null) {
                  print(
                      'Error updating pin status: ${updateResponse.error.message}, Code: ${updateResponse.error!.code}');
                } else {
                  print('Pin status updated successfully.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف'),
              onTap: () => ontapFunction(),
            ),
          ],
        ),
      );
    },
  );
}

final picker = ImagePicker();

Future<void> uploadProfilePicture() async {
  // انتخاب عکس از گالری
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File file = File(pickedFile.path);

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      // آپلود عکس به باکت
      final fileName = 'public/$userId/profile-pic.png';
      final response = await Supabase.instance.client.storage
          .from('user-profile-pics')
          .upload(fileName, file);

      print('خطا در آپلود عکس: $response');
    }
  }
}

class NoteGridWidget extends ConsumerWidget {
  final List<Note> notes;
  final WidgetRef ref;

  const NoteGridWidget({super.key, required this.notes, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider); // دریافت تم جاری

    return MasonryGridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        // استایل‌ها بر اساس تم جاری
        final containerDecoration = BoxDecoration(
          color: currentTheme.brightness == Brightness.dark
              ? Colors.grey[800] // رنگ پس‌زمینه برای تم تاریک
              : Colors.grey[300], // رنگ پس‌زمینه برای تم روشن
          borderRadius: BorderRadius.circular(
            currentTheme == redWhiteTheme ||
                    currentTheme == yellowBlackTheme ||
                    currentTheme == tealWhiteTheme
                ? 20.0
                : 10.0, // شکل متفاوت برای تم سفارشی
          ),
          boxShadow: currentTheme == redWhiteTheme
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              : (currentTheme == yellowBlackTheme
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : (currentTheme == tealWhiteTheme
                      ? [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [])),
        );
        return GestureDetector(
          onLongPress: () {
            showCustomBottomSheet(context, note, () {
              ref.read(deleteNoteProvider(note.id));
              ref.refresh(notesProvider);
              Navigator.pop(context);
            });
          },
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddNoteScreen(
                          note: note,
                        )));
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: containerDecoration, // استفاده از استایل داینامیک
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazir',
                    color: currentTheme.brightness == Brightness.dark
                        ? Colors.white // رنگ متن برای تم تاریک
                        : Colors.black, // رنگ متن برای تم روشن
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    color: currentTheme.brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54, // رنگ متن با توجه به تم
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Route createSearchPageRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // تنظیم انیمیشن حرکت از راست به چپ
      const begin = Offset(1.0, 0.0); // شروع از خارج صفحه سمت راست
      const end = Offset.zero; // پایان در وسط صفحه
      const curve = Curves.easeInOut; // منحنی برای روان بودن انیمیشن

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      // تنظیم انیمیشن برای تغییر شفافیت
      var opacityTween =
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        ),
      );
    },
  );
}

//CustomDrawer

Drawer CustomDrawer(AsyncValue<Map<String, dynamic>?> getprofile,
    ThemeData currentcolor, BuildContext context) {
  return Drawer(
    width: 0.6.sw,
    child: Column(
      children: <Widget>[
        DrawerHeader(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: getprofile.when(
              data: (getprofile) {
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                      color: currentcolor.appBarTheme.backgroundColor),
                  currentAccountPicture: CircleAvatar(
                    radius: 30,
                    backgroundImage: getprofile!['avatar_url'] != null
                        ? NetworkImage(getprofile['avatar_url'].toString())
                        : const AssetImage(
                            'lib/util/images/default-avatar.jpg'),
                  ),
                  margin: const EdgeInsets.only(bottom: 0),
                  currentAccountPictureSize: const Size(65, 65),
                  accountName: Text(
                    '${getprofile['username']}',
                    style: TextStyle(
                        color: currentcolor.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black),
                  ),
                  accountEmail: Text("${supabase.auth.currentUser!.email}",
                      style: TextStyle(
                          color: currentcolor.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)),
                );
              },
              error: (error, stack) {
                final errorMsg = error.toString() == 'User is not logged in'
                    ? 'کاربر وارد سیستم نشده است، لطفاً ورود کنید.'
                    : 'خطا در دریافت اطلاعات کاربر، لطفاً دوباره تلاش کنید.';

                return Center(child: Text(errorMsg));
              },
              loading: () => const Center(child: CircularProgressIndicator())),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text(
            'تنظیمات',
          ),
          onTap: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text(
            'پشتیبانی',
          ),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SupportPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text(
            'دعوت از دوستان',
          ),
          onTap: () {
            const String inviteText =
                'دوست عزیز سلام! من از ویستا نوت برای ذخیره یادداشت هام استفاده میکنم! \n امکانات این نرم افزار بی نظیره میتونی از این لینک از طریق مایکت دانلودش کنی:  https://myket.ir/app/com.example.vista_notes2 ';
            Share.share(inviteText);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text(
            'خروج',
          ),
          onTap: () {
            supabase.auth.signOut();
            Navigator.pushReplacementNamed(context, '/welcome');
          },
        ),
      ],
    ),
  );
}

//report function

class ReportDialog extends ConsumerStatefulWidget {
  final PublicPostModel post;

  const ReportDialog({Key? key, required this.post}) : super(key: key);

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String selectedReason = '';
  final List<String> reportReasons = [
    'محتوای نامناسب',
    'هرزنگاری',
    'توهین آمیز',
    'اسپم',
    'محتوای تبلیغاتی',
    'سایر موارد'
  ];

  TextEditingController additionalDetailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('گزارش پست'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('دلیل گزارش پست را انتخاب کنید:'),
            ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                )),
            if (selectedReason == 'سایر موارد')
              TextField(
                controller: additionalDetailsController,
                decoration: InputDecoration(
                  hintText: 'جزئیات بیشتر را وارد کنید',
                ),
                maxLines: 3,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedReason.isNotEmpty) {
              _submitReport();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('لطفاً دلیل گزارش را انتخاب کنید')),
              );
            }
          },
          child: Text('ثبت گزارش'),
        ),
      ],
    );
  }

  void _submitReport() async {
    try {
      // ذخیره گزارش در سوپابیس
      final supabase = ref.read(supabaseServiceProvider);

      await supabase.insertReport(
          postId: widget.post.id,
          reportedUserId: widget.post.userId,
          reason: selectedReason,
          additionalDetails: selectedReason == 'سایر موارد'
              ? additionalDetailsController.text
              : null);

      // نمایش پیام موفقیت
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('گزارش شما ثبت شد')),
      );

      Navigator.pop(context);
    } catch (e) {
      // نمایش خطا
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ثبت گزارش: $e')),
      );
    }
  }
}
