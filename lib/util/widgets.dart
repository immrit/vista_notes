import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../provider/provider.dart';

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
          "${text}",
          style: const TextStyle(fontSize: 28),
        ),
      ),
    ),
  );
}

class AddNoteWidget extends ConsumerStatefulWidget {
  @override
  _AddNoteWidgetState createState() => _AddNoteWidgetState();
}

class _AddNoteWidgetState extends ConsumerState<AddNoteWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Enter note title',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await addNote();
            Navigator.pop(context);
          },
          child: const Text('Add Note'),
        ),
      ],
    );
  }

  Future<void> addNote() async {
    final title = _controller.text;

    // ارسال یادداشت به Supabase
    await supabase.from('Notes').insert({
      'title': title,
      'user_id':
          supabase.auth.currentSession!.user.id, // اضافه کردن شناسه کاربر
    });

    // بازخوانی لیست یادداشت‌ها پس از اضافه کردن یادداشت جدید
    ref.invalidate(notesProvider);

    // پاک کردن فیلد ورودی
    _controller.clear();
  }
}

Future showMyDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // پاپ‌آپ با کلیک بیرون از آن بسته می‌شود
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'سریع بنویس...',
          style: TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(child: AddNoteWidget()),
      );
    },
  );
}
