import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/homeScreen.dart';

import '../../../main.dart';

class SetProfileData extends StatefulWidget {
  const SetProfileData({super.key});

  @override
  State<SetProfileData> createState() => _SetProfileDataState();
}

class _SetProfileDataState extends State<SetProfileData> {
  final _usernameController = TextEditingController();
  File? _imageFile;
  final picker = ImagePicker();
  var _loading = true;

  /// واکشی پروفایل
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();
      _usernameController.text = (data['username'] ?? '') as String;
      final avatarUrl = data['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        if (mounted) {
          setState(() {
            _imageFile = File(avatarUrl);
          });
        }
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('خطا در بازیابی پروفایل', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// انتخاب تصویر
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }

      // آپلود تصویر به Supabase
      await _uploadImage(_imageFile!);
    }
  }

  /// آپلود تصویر به فضای ذخیره‌سازی Supabase
  Future<void> _uploadImage(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // آپلود به فضای ذخیره‌سازی
      final storageResponse =
          await supabase.storage.from('avatars').upload(fileName, imageFile);

      // دریافت URL عمومی
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // ذخیره URL تصویر در جدول profiles
      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تصویر با موفقیت آپلود شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در آپلود تصویر: $e')),
        );
      }
    }
  }

  /// به‌روزرسانی پروفایل
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
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
      if (mounted) {
        context.showSnackBar('پروفایل با موفقیت به‌روزرسانی شد!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بروزرسانی پروفایل: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
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
                      : const AssetImage('lib/util/images/vistalogo.png')
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
          }, false),
          const SizedBox(height: 18),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            right: 10,
            left: 10),
        child: customButton(_loading ? null : _updateProfile,
            _loading ? 'در حال ذخیره‌سازی...' : 'ذخیره'),
      ),
    );
  }
}
