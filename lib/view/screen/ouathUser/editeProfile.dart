import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/util/widgets.dart';
import '../../../provider/provider.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final TextEditingController _usernameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();

  // متد برای نمایش دیالوگ
  void _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_a_photo),
                title: const Text('افزودن تصویر جدید'),
                onTap: () async {
                  Navigator.of(context).pop(); // بستن باتم شیت
                  await _pickImage(); // انتخاب تصویر جدید
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('حذف عکس پروفایل'),
                onTap: () async {
                  Navigator.of(context).pop(); // بستن باتم شیت
                  await _deleteImage(); // حذف تصویر پروفایل
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteImage() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // دریافت URL عکس پروفایل فعلی از پروفایل کاربر
      final profileResponse = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      final previousAvatarUrl = profileResponse['avatar_url'];

      // حذف عکس از باکت اگر وجود داشته باشد
      if (previousAvatarUrl != null && previousAvatarUrl.isNotEmpty) {
        final fileNameToDelete = previousAvatarUrl.split('/').last;
        await supabase.storage.from('avatars').remove([fileNameToDelete]);

        // به‌روزرسانی URL تصویر پروفایل به null
        await supabase
            .from('profiles')
            .update({'avatar_url': null}).eq('id', userId);

        // نمایش پیام موفقیت
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عکس پروفایل حذف شد')),
        );

        // به‌روزرسانی UI
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در حذف تصویر: $e')),
      );
      print('Error deleting image: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // آپلود تصویر به Supabase
      await _uploadImage(_imageFile!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // دریافت URL عکس پروفایل فعلی از پروفایل کاربر
      final profileResponse = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      final previousAvatarUrl = profileResponse['avatar_url'];

      // حذف عکس قبلی از باکت اگر وجود داشته باشد
      if (previousAvatarUrl != null && previousAvatarUrl.isNotEmpty) {
        final fileNameToDelete = previousAvatarUrl.split('/').last;
        await supabase.storage.from('avatars').remove([fileNameToDelete]);
      }

      // نام فایل جدید برای ذخیره
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // آپلود تصویر به فضای ذخیره‌سازی Supabase
      final storageResponse = await supabase.storage
          .from('avatars') // نام باکت
          .upload(fileName, imageFile);

      // دریافت URL عمومی فایل آپلود شده
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // ذخیره URL تصویر در جدول profiles
      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', userId);

      // بررسی اینکه ویجت هنوز mounted است
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تصویر با موفقیت آپلود شد')),
        );

        // به‌روزرسانی UI برای نمایش تصویر جدید
        setState(() {});
      }
    } catch (e) {
      // بررسی اینکه ویجت هنوز mounted است
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در آپلود تصویر: $e')),
        );
      }
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final getProfileData = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش پروفایل'),
      ),
      body: getProfileData.when(
        data: (data) {
          final avatarUrl = data!['avatar_url']; // دریافت URL تصویر پروفایل
          if (_usernameController.text.isEmpty) {
            _usernameController.text =
                data['username'] ?? ""; // دریافت نام کاربری فعلی
          }
          if (fullNameController.text.isEmpty) {
            fullNameController.text =
                data['full_name'] ?? ""; // دریافت نام کاربری فعلی
          }
          if (bioController.text.isEmpty) {
            bioController.text = data['bio'] ?? ""; // دریافت بیو
          }

          return Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageOptions, // نمایش دیالوگ با گزینه‌ها
                    child: Container(
                      width: .16.sh,
                      height: .16.sh,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage(
                                      'lib/util/images/default-avatar.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
                  customTextField('نام کاربری', _usernameController, (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفا مقادیر را وارد نمایید';
                    }
                  }, false, TextInputType.text),
                  SizedBox(height: 20.h),
                  customTextField('نام', fullNameController, (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفا مقادیر را وارد نمایید';
                    }
                  }, false, TextInputType.text),
                  SizedBox(height: 20.h),
                  customTextField('درباره شما', bioController, (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفا مقادیر را وارد نمایید';
                    }
                  }, false, TextInputType.text)
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          right: 10,
          left: 10,
        ),
        child: customButton(() {
          final updatedData = {
            'username': _usernameController.text,
            'full_name': fullNameController.text,
            'bio': bioController.text
          };
          ref.refresh(profileProvider);
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اطلاعات بروزرسانی شد')),
          );
          ref.read(profileUpdateProvider(updatedData)).when(
                data: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تصویر پروفایل بروزرسانی شد')),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('خطا در بروزرسانی تصویر پروفایل: $error')),
                ),
              );
        }, 'ذخیره', ref),
      ),
    );
  }
}
