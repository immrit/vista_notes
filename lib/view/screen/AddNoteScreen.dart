import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';
import 'package:vistaNote/util/widgets.dart';

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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('افزودن یادداشت'),
      ),
      body: ListView(
        children: [
          Column(
            children: [
              addNotesTextFiels('موضوع', 1, _titleController),
              SizedBox(height: 5.h),
              addNotesTextFiels('هرچه میخواهی بگو...', 5, _contentController),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('ذخیره یادداشت'),
        icon: Icon(Icons.add),
        onPressed: _addNote,
        // shape: const CircleBorder(),
        // isExtended: true,
        backgroundColor: Colors.white,
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
