import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';

import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/homeScreen.dart';

import '../../model/Notes.dart';
import '../../provider/provider.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  final Note? note;
  AddNoteScreen({
    this.note,
  });

  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    // titleController = TextEditingController();
    // contentController = TextEditingController();

    if (widget.note != null) {
      isEditing = true;
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (isEditing) {
      // final updatedData = {
      //   'id': widget.note!.id,
      //   'title': titleController.text,
      //   'content': contentController.text,
      // };
      await _editeNote(); // ویرایش یادداشت
    } else {
      // final newNoteData = {
      //   'title': titleController.text,
      //   'content': contentController.text,
      // };
      await _addNote(); // افزودن یادداشت
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    // بازگشت به صفحه قبل
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.sp),
        iconTheme: const IconThemeData(color: Colors.white),
        title: isEditing == true ? Text('ویرایش') : Text('افزودن نوشته جدید'),
      ),
      body: ListView(
        children: [
          Column(
            children: [
              addNotesTextFiels('موضوع', 1, titleController),
              SizedBox(height: 5.h),
              addNotesTextFiels('هرچه میخواهی بگو...', 5, contentController),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('ذخیره یادداشت'),
        icon: const Icon(Icons.add),
        onPressed: _saveNote,
        // shape: const CircleBorder(),
        // isExtended: true,
        backgroundColor: Colors.white,
      ),
    );
  }

//Add Note

  Future<void> _addNote() async {
    final title = titleController.text;
    final content = contentController.text;

    // ارسال یادداشت به Supabase
    await supabase.from('Notes').insert({
      'title': title,
      'content': content,
      'user_id': Supabase.instance.client.auth.currentSession!.user
          .id, // اضافه کردن شناسه کاربر
    });

    // بازخوانی لیست یادداشت‌ها پس از اضافه کردن یادداشت جدید
    ref.invalidate(notesProvider);

    // بازگشت به صفحه اصلی
    Navigator.of(context).pop();
  }

  // Edite Note
  Future<void> _editeNote() async {
    final title = titleController.text;
    final content = contentController.text;

    // ارسال یادداشت به Supabase
    await supabase.from('Notes').update({
      'title': title,
      'content': content,
      'user_id': Supabase.instance.client.auth.currentSession!.user
          .id, // اضافه کردن شناسه کاربر
    }).eq('id', widget.note!.id);

    // بازخوانی لیست یادداشت‌ها پس از اضافه کردن یادداشت جدید
    ref.invalidate(notesProvider);

    // بازگشت به صفحه اصلی
    Navigator.of(context).pop();
  }
}
