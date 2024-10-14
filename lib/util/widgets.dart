import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';
import 'package:vistaNote/model/Notes.dart';
import 'package:vistaNote/view/screen/AddNoteScreen.dart';

import '../provider/provider.dart';
import '../view/screen/searchPage.dart';

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
          style: const TextStyle(
              fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
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
        style: const TextStyle(color: Colors.white),
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        cursorColor: Colors.white,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white60),
          focusColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.white, // رنگ بوردر در حالت غیرفعال (enabled)
              width: .7,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.white, // رنگ بوردر در حالت فوکوس (focused)
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ),
  );
}

Widget customButton(dynamic ontap, String text) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      width: 350,
      height: 50,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    ),
  );
}

Widget ProfileFields(String name, IconData icon, dynamic onclick) {
  return GestureDetector(
    onTap: onclick,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
          width: double.infinity,
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: ListTile(
              leading: Icon(
                icon,
                color: Colors.white54,
              ),
              title: Text(
                name,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
              ),
            ),
          )),
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
            hintStyle: TextStyle(fontSize: 25.sp, color: Colors.white30)),
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

class NoteGridWidget extends StatelessWidget {
  final List<Note> notes;
  final WidgetRef ref;

  const NoteGridWidget({super.key, required this.notes, required this.ref});

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 10),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white54, fontFamily: 'Vazir'),
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
