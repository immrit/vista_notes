import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/model/Notes.dart';
import 'package:vistaNote/view/screen/AddNoteScreen.dart';

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
    dynamic validator, bool obscureText) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        style: const TextStyle(color: Colors.white),
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white60),
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.white,
              width: 4,
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
    String name, int lines, TextEditingController controller) {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        maxLines: lines,
        controller: controller,
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
          mainAxisSize: MainAxisSize.min, // اندازه مینیمم برای ستون
          children: [
            ListTile(
              leading:
                  const Icon(Icons.edit, color: Colors.blue), // آیکون ویرایش
              title: const Text('ویرایش'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddNoteScreen(
                              note: note,
                            )));
                // کد مربوط به ویرایش را اینجا قرار دهید
              },
            ),
            ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red), // آیکون حذف
                title: const Text('حذف'),
                onTap: () => ontapFunction()),
          ],
        ),
      );
    },
  );
}
