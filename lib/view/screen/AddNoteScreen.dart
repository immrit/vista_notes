import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';

import '../../provider/provider.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.sp),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('افزودن یادداشت'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addNote,
              child: Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    // ارسال یادداشت به Supabase
    await Supabase.instance.client.from('Notes').insert({
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
}
