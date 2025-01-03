import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/Notes/NotesPage.dart';

import '../../../main.dart';

// وضعیت بارگذاری
final loadingProvider = StateProvider<bool>((ref) => true);

// کلاس اصلی
class SetProfileData extends ConsumerStatefulWidget {
  const SetProfileData({super.key});

  @override
  _SetProfileDataState createState() => _SetProfileDataState();
}

class _SetProfileDataState extends ConsumerState<SetProfileData> {
  final _usernameController = TextEditingController();
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  // واکشی پروفایل
  Future<void> _getProfile() async {
    ref.read(loadingProvider.notifier).state = true;

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();
      _usernameController.text = (data['username'] ?? '') as String;
      final avatarUrl = data['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        _imageFile = File(avatarUrl);
      }
    } catch (error) {
      context.showSnackBar('خطا در بازیابی پروفایل', isError: true);
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  // انتخاب تصویر
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      await _uploadImage(_imageFile!);
    }
  }

  // آپلود تصویر
  Future<void> _uploadImage(File imageFile) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // آپلود به فضای ذخیره‌سازی
      await supabase.storage.from('avatars').upload(fileName, imageFile);

      // دریافت URL عمومی
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // ذخیره URL تصویر در جدول profiles
      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تصویر با موفقیت آپلود شد')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در آپلود تصویر: $e')),
      );
    }
  }

  // به‌روزرسانی پروفایل
  Future<void> _updateProfile() async {
    ref.read(loadingProvider.notifier).state = true;
    final userName = _usernameController.text.trim();
    final user = supabase.auth.currentUser;

    final updates = {
      'id': user!.id,
      'username': userName,
      'updated_at': DateTime.now().toIso8601String(),
      'email': user.email
    };

    try {
      await supabase.from('profiles').upsert(updates);
      context.showSnackBar('پروفایل با موفقیت به‌روزرسانی شد!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بروزرسانی پروفایل: $error')),
      );
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نام کاربری خود را مشخص کنید'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('lib/util/images/default-avatar.jpg')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          customTextField('نام کاربری', _usernameController, (value) {
            if (value == null || value.isEmpty) {
              return 'لطفا مقادیر را وارد نمایید';
            }
          }, false, TextInputType.text),
          const SizedBox(height: 18),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(loading ? null : _updateProfile,
            loading ? 'در حال ذخیره‌سازی...' : 'ذخیره', ref),
      ),
    );
  }
}
