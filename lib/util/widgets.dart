import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

Widget customTextField(String hintText, TextEditingController controller) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        style: const TextStyle(color: Colors.white),
        controller: controller,
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

Widget customButtonSignUpORIn(dynamic ontap, String text) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      width: 350,
      height: 65,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: const TextStyle(fontSize: 28),
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
void showCustomBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // اندازه مینیمم برای ستون
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue), // آیکون ویرایش
              title: Text('ویرایش'),
              onTap: () {
                // عملکرد ویرایش
                Navigator.pop(context);
                // کد مربوط به ویرایش را اینجا قرار دهید
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red), // آیکون حذف
              title: Text('حذف'),
              onTap: () {
                // عملکرد حذف
                Navigator.pop(context);
                // کد مربوط به حذف را اینجا قرار دهید
              },
            ),
          ],
        ),
      );
    },
  );
}
