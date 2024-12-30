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
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser!.id;

      // دریافت URL عکس پروفایل فعلی
      final profileResponse = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      final previousAvatarUrl = profileResponse['avatar_url'] as String?;

      if (previousAvatarUrl != null) {
        // حذف فایل از باکت
        final fileName = previousAvatarUrl.split('/').last;
        await supabase.storage.from('avatars').remove([fileName]);

        // به‌روزرسانی پروفایل
        await supabase
            .from('profiles')
            .update({'avatar_url': null}).eq('id', userId);

        setState(() {
          _imageFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عکس پروفایل حذف شد')),
          );
        }
      }
    } catch (e) {
      print('Error deleting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف تصویر: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // محدود کردن سایز تصویر
        maxHeight: 1024,
        imageQuality: 85, // کاهش کیفیت برای کاهش حجم
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // بررسی وجود فایل
        if (await imageFile.exists()) {
          setState(() {
            _imageFile = imageFile;
          });
          await _uploadImage(imageFile);
        } else {
          throw Exception('فایل انتخاب شده در مسیر مورد نظر یافت نشد');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در انتخاب تصویر: $e')),
        );
      }
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('فایل تصویر وجود ندارد');
      }

      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // بررسی سایز فایل (محدودیت 5 مگابایت)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('حجم فایل بیشتر از حد مجاز است');
      }

      // حذف عکس قبلی از باکت اگر وجود داشته باشد
      final profileData = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .single();

      final previousAvatarUrl = profileData['avatar_url'] as String?;
      if (previousAvatarUrl != null) {
        final previousPath = previousAvatarUrl.split('/').last;
        await supabase.storage.from('avatars').remove([previousPath]);
      }

      // آپلود عکس جدید
      final fileExtension = imageFile.path.split('.').last;
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final storageResponse = await supabase.storage
          .from('avatars') // نام باکت شما در سوپابیس
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      if (storageResponse.isEmpty) {
        throw Exception('آپلود تصویر شکست خورد');
      }

      // دریافت URL عمومی فایل
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // به‌روزرسانی URL تصویر در پروفایل کاربر
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تصویر با موفقیت آپلود شد')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در آپلود تصویر: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final getProfileData = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش پروفایل'),
      ),
      body: ListView(
        children: [
          getProfileData.when(
            data: (data) {
              final avatarUrl = data!['avatar_url']; // دریافت URL تصویر پروفایل
              if (_usernameController.text.isEmpty) {
                _usernameController.text =
                    data['username'] ?? ""; // دریافت نام کاربری فعلی
              }
              if (fullNameController.text.isEmpty) {
                fullNameController.text = data['full_name'] ?? ""; // دریافت نام
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
                      customTextField('نام کاربری', _usernameController,
                          (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفا مقادیر را وارد نمایید';
                        }
                        if (!RegExp(r'^[a-z._-]{5,}$').hasMatch(value)) {
                          return 'نام کاربری باید حداقل ۵ حرف داشته باشد و فقط از حروف کوچک، _، - و . استفاده کنید';
                        }
                        return null;
                      }, false, TextInputType.text),
                      SizedBox(height: 20.h),
                      customTextField('نام', fullNameController, (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفا مقادیر را وارد نمایید';
                        }
                        return null;
                      }, false, TextInputType.text),
                      SizedBox(height: 20.h),
                      customTextField('درباره شما', bioController, (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفا مقادیر را وارد نمایید';
                        }
                        return null;
                      }, false, TextInputType.text)
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          right: 10,
          left: 10,
        ),
        child: customButton(() {
          final userName = _usernameController.text.trim();
          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(userName)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'لطفاً فقط از حروف انگلیسی در نام کاربری استفاده کنید')),
            );
            return;
          }

          final updatedData = {
            'username': userName,
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
