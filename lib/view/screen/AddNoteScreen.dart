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
  bool isLoading = false;

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

  Future<void> _saveNote() async {
    if (isEditing) {
      await _editeNote(); // ویرایش یادداشت
    } else {
      await _addNote(); // افزودن یادداشت
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    // بازگشت به صفحه قبل
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        title: isEditing == true ? Text('ویرایش') : Text('افزودن نوشته جدید'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Column(
            children: [
              addNotesTextFiels(
                'موضوع',
                1,
                titleController,
                18,
                FontWeight.bold,
                null,
              ),
              SizedBox(height: 5.h),
              addNotesTextFiels('هرچه میخواهی بگو...', 50, contentController,
                  18, FontWeight.normal, 1000),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),

      // ),

      floatingActionButton: ElevatedButton(
        onPressed: isLoading ? null : _saveNote,
        child: isLoading
            ? CircularProgressIndicator()
            : Text(
                isEditing ? "ویرایش" : "افزودن",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(10, 50),
        ),
      ),
    );
  }

//Add Note

  Future<void> _addNote() async {
    final title = titleController.text;
    final content = contentController.text;
    setState(() {
      isLoading = true;
    });
    // ارسال یادداشت به Supabase
    await supabase.from('Notes').insert({
      'title': title,
      'content': content,
      'user_id': Supabase.instance.client.auth.currentSession!.user
          .id, // اضافه کردن شناسه کاربر
    });

    // بازخوانی لیست یادداشت‌ها پس از اضافه کردن یادداشت جدید
    ref.invalidate(notesProvider);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    // بازگشت به صفحه اصلی
    Navigator.of(context).pop();
  }

  // Edite Note
  Future<void> _editeNote() async {
    final title = titleController.text;
    final content = contentController.text;
    setState(() {
      isLoading = true;
    });
    // ارسال یادداشت به Supabase
    await supabase.from('Notes').update({
      'title': title,
      'content': content,
      'user_id': Supabase.instance.client.auth.currentSession!.user
          .id, // اضافه کردن شناسه کاربر
    }).eq('id', widget.note!.id);

    // بازخوانی لیست یادداشت‌ها پس از اضافه کردن یادداشت جدید
    ref.invalidate(notesProvider);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    // بازگشت به صفحه اصلی
    Navigator.of(context).pop();
  }
}
