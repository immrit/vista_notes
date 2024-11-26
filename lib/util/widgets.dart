import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/main.dart';
import 'package:vistaNote/model/NotesModel.dart';
import 'package:vistaNote/util/const.dart';
import 'package:vistaNote/view/screen/Notes/AddNoteScreen.dart';
import '../model/CommentModel.dart';
import '../model/UserModel.dart';
import '../model/publicPostModel.dart';
import '../provider/provider.dart';
import '../view/screen/PublicPosts/profileScreen.dart';
import '../view/screen/searchPage.dart';
import '../view/screen/support.dart';
import 'themes.dart';

class topText extends StatelessWidget {
  String text;
  topText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Text(
          text,
          style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

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

Widget customTextField(String hintText, TextEditingController controller,
    dynamic validator, bool obscureText, TextInputType keyboardType) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: .7,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ),
  );
}

Widget customButton(dynamic ontap, String text, final WidgetRef ref) {
  final currentTheme = ref.watch(themeProvider); // دریافت تم جاری

  return GestureDetector(
    onTap: ontap,
    child: Container(
      width: 350,
      height: 50,
      decoration: BoxDecoration(
          color: currentTheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(15)),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: TextStyle(
            fontSize: 20,
            color: currentTheme.brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget ProfileFields(String name, IconData icon, dynamic onclick) {
  return GestureDetector(
    onTap: onclick,
    child: Column(
      children: [
        SizedBox(
            width: double.infinity,
            height: 45,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  icon,
                ),
                title: Text(
                  name,
                ),
              ),
            )),
        const Divider(indent: 0, endIndent: 59),
      ],
    ),
  );
}

Widget addNotesTextFiels(
    String name,
    int lines,
    TextEditingController controller,
    double fontSize,
    FontWeight fontWeight,
    param5,
    {int? maxLength}) {
  return Container(
    padding: const EdgeInsets.all(20),
    child: Directionality(
      textDirection: getDirectionality(controller.text),
      child: TextField(
        maxLines: lines,
        textAlign: getTextAlignment(controller.text),
        maxLength: maxLength,
        controller: controller,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        scrollPhysics: const NeverScrollableScrollPhysics(),
        decoration: InputDecoration(
            hintText: name,
            border: InputBorder.none,
            hintStyle: TextStyle(fontSize: 20.sp)),
      ),
    ),
  );
}

//bottomSheet
void showCustomBottomSheet(
    BuildContext context, Note note, Function ontapFunction) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('ویرایش'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddNoteScreen(note: note)));
              },
            ),
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? Colors.orange : Colors.grey,
              ),
              title: Text(note.isPinned ? 'برداشتن پین' : 'پین کردن'),
              onTap: () async {
                Navigator.pop(context); // بستن BottomSheet

                // تغییر وضعیت پین در مدل
                final updatedNote = note.copyWith(isPinned: !note.isPinned);

                // بررسی وجود یادداشت در پایگاه داده
                final response =
                    await supabase.from('Notes').select().eq('id', note.id);

                if (response.isEmpty) {
                  print('Note not found in database');
                  return;
                }

                // به‌روزرسانی وضعیت پین در Supabase
                final updateResponse = await supabase.from('Notes').update(
                    {'is_pinned': updatedNote.isPinned}).eq('id', note.id);

                if (updateResponse.error != null) {
                  print(
                      'Error updating pin status: ${updateResponse.error.message}, Code: ${updateResponse.error!.code}');
                } else {
                  print('Pin status updated successfully.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف'),
              onTap: () => ontapFunction(),
            ),
          ],
        ),
      );
    },
  );
}

final picker = ImagePicker();

Future<void> uploadProfilePicture() async {
  // انتخاب عکس از گالری
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File file = File(pickedFile.path);

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      // آپلود عکس به باکت
      final fileName = 'public/$userId/profile-pic.png';
      final response = await Supabase.instance.client.storage
          .from('user-profile-pics')
          .upload(fileName, file);

      print('خطا در آپلود عکس: $response');
    }
  }
}

class NoteGridWidget extends ConsumerWidget {
  final List<Note> notes;
  final WidgetRef ref;

  const NoteGridWidget({super.key, required this.notes, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider); // دریافت تم جاری

    return MasonryGridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        // استایل‌ها بر اساس تم جاری
        final containerDecoration = BoxDecoration(
          color: currentTheme.brightness == Brightness.dark
              ? Colors.grey[800] // رنگ پس‌زمینه برای تم تاریک
              : Colors.grey[300], // رنگ پس‌زمینه برای تم روشن
          borderRadius: BorderRadius.circular(
            currentTheme == redWhiteTheme ||
                    currentTheme == yellowBlackTheme ||
                    currentTheme == tealWhiteTheme
                ? 20.0
                : 10.0, // شکل متفاوت برای تم سفارشی
          ),
          boxShadow: currentTheme == redWhiteTheme
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              : (currentTheme == yellowBlackTheme
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : (currentTheme == tealWhiteTheme
                      ? [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [])),
        );
        return GestureDetector(
          onLongPress: () {
            showCustomBottomSheet(context, note, () {
              ref.read(deleteNoteProvider(note.id));
              ref.invalidate(notesProvider);
              Navigator.pop(context);
            });
          },
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddNoteScreen(
                          note: note,
                        )));
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: containerDecoration, // استفاده از استایل داینامیک
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazir',
                    color: currentTheme.brightness == Brightness.dark
                        ? Colors.white // رنگ متن برای تم تاریک
                        : Colors.black, // رنگ متن برای تم روشن
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    color: currentTheme.brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54, // رنگ متن با توجه به تم
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Route createSearchPageRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // تنظیم انیمیشن حرکت از راست به چپ
      const begin = Offset(1.0, 0.0); // شروع از خارج صفحه سمت راست
      const end = Offset.zero; // پایان در وسط صفحه
      const curve = Curves.easeInOut; // منحنی برای روان بودن انیمیشن

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      // تنظیم انیمیشن برای تغییر شفافیت
      var opacityTween =
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        ),
      );
    },
  );
}

//CustomDrawer

Drawer CustomDrawer(AsyncValue<Map<String, dynamic>?> getprofile,
    ThemeData currentcolor, BuildContext context) {
  return Drawer(
    width: 0.6.sw,
    child: Column(
      children: <Widget>[
        DrawerHeader(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: getprofile.when(
              data: (getprofile) {
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                      color: currentcolor.appBarTheme.backgroundColor),
                  currentAccountPicture: CircleAvatar(
                    radius: 30,
                    backgroundImage: getprofile!['avatar_url'] != null
                        ? NetworkImage(getprofile['avatar_url'].toString())
                        : const AssetImage(
                            'lib/util/images/default-avatar.jpg'),
                  ),
                  margin: const EdgeInsets.only(bottom: 0),
                  currentAccountPictureSize: const Size(65, 65),
                  accountName: Row(
                    children: [
                      Text(
                        '${getprofile['username']}',
                        style: TextStyle(
                            color: currentcolor.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      if (getprofile['is_verified'])
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 16),
                    ],
                  ),
                  accountEmail: Text("${supabase.auth.currentUser!.email}",
                      style: TextStyle(
                          color: currentcolor.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)),
                );
              },
              error: (error, stack) {
                final errorMsg = error.toString() == 'User is not logged in'
                    ? 'کاربر وارد سیستم نشده است، لطفاً ورود کنید.'
                    : 'خطا در دریافت اطلاعات کاربر، لطفاً دوباره تلاش کنید.';

                return Center(child: Text(errorMsg));
              },
              loading: () => const Center(child: CircularProgressIndicator())),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text(
            'تنظیمات',
          ),
          onTap: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text(
            'پشتیبانی',
          ),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SupportPage()));
          },
        ),
        // ListTile(
        //   leading: const Icon(Icons.person_add),
        //   title: const Text(
        //     'دعوت از دوستان',
        //   ),
        //   onTap: () {
        //     const String inviteText =
        //         'دوست عزیز سلام! من از ویستا نوت برای ذخیره یادداشت هام و ارتباط با کلی رفیق جدید استفاده میکنم! \n پیشنهاد میکنم همین الان از بازار نصبش کنی😉:  https://cafebazaar.ir/app/com.example.vista_notes2/ ';
        //     Share.share(inviteText);
        //   },
        // ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text(
            'خروج',
          ),
          onTap: () {
            supabase.auth.signOut();
            Navigator.pushReplacementNamed(context, '/welcome');
          },
        ),
      ],
    ),
  );
}

//report function

class ReportDialog extends ConsumerStatefulWidget {
  final PublicPostModel post;

  const ReportDialog({super.key, required this.post});

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  // لیست دلایل گزارش
  final List<String> reportReasons = [
    'محتوای نامناسب',
    'هرزنگاری',
    'توهین آمیز',
    'اسپم',
    'محتوای تبلیغاتی',
    'سایر موارد'
  ];

  // متغیرهای حالت
  String _selectedReason = '';
  late TextEditingController _additionalDetailsController;

  @override
  void initState() {
    super.initState();
    _additionalDetailsController = TextEditingController();
  }

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    super.dispose();
  }

  // متد ارسال گزارش
  void _submitReport() async {
    try {
      // دریافت سرویس سوپابیس از پرووایدر
      final supabaseService = ref.read(supabaseServiceProvider);

      // بررسی انتخاب دلیل
      if (_selectedReason.isEmpty) {
        _showSnackBar('لطفاً دلیل گزارش را انتخاب کنید', isError: true);
        return;
      }

      // ارسال گزارش
      await supabaseService.insertReport(
        postId: widget.post.id,
        reportedUserId: widget.post.userId,
        reason: _selectedReason,
        additionalDetails: _selectedReason == 'سایر موارد'
            ? _additionalDetailsController.text.trim()
            : null,
      );
      // بستن دیالوگ و نمایش پیام موفقیت
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('گزارش شما با موفقیت ثبت شد');
      }
    } catch (e) {
      // نمایش خطا
      if (mounted) {
        _showSnackBar('خطا در ثبت گزارش: $e', isError: true);
      }
    }
  }

  // متد نمایش اسنک بار
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'گزارش پست',
        style: theme.textTheme.titleMedium,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دلیل گزارش پست را انتخاب کنید:',
              style: theme.textTheme.bodyMedium,
            ),
            // لیست رادیویی دلایل گزارش
            ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(
                    reason,
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                  activeColor: theme.colorScheme.secondary,
                )),

            // فیلد توضیحات اضافی برای 'سایر موارد'
            if (_selectedReason == 'سایر موارد')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _additionalDetailsController,
                  decoration: InputDecoration(
                    hintText: 'جزئیات بیشتر را وارد کنید',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
      actions: [
        // دکمه انصراف
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),

        // دکمه ارسال گزارش
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          onPressed: _selectedReason.isNotEmpty ? _submitReport : null,
          child: const Text('ثبت گزارش'),
        ),
      ],
    );
  }
}

//jeneral text field

bool isPersian(String text) {
  // بررسی می‌کند آیا متن دارای حروف فارسی است یا نه
  final RegExp persianRegExp = RegExp(r'[\u0600-\u06FF]');
  return persianRegExp.hasMatch(text);
}

TextAlign getTextAlignment(String text) {
  return isPersian(text) ? TextAlign.right : TextAlign.left;
}

TextDirection getDirectionality(String text) {
  return isPersian(text) ? TextDirection.rtl : TextDirection.ltr;
}

void showCommentsBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String postId,
  String userId,
) {
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();
  final List<UserModel> mentionedUsers = [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Comments List
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final commentsAsyncValue =
                            ref.watch(commentsProvider(postId));

                        return commentsAsyncValue.when(
                          data: (comments) => comments.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Column(
                                    // crossAxisAlignment:
                                    //     CrossAxisAlignment.center,
                                    // mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.message_rounded),
                                      Text('هنوز کامنتی وجود ندارد'),
                                    ],
                                  ))
                              : _buildCommentsList(
                                  context, ref, comments, userId),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => const Center(
                              child: Text('خطا در بارگذاری کامنت‌ها')),
                        );
                      },
                    ),
                  ),

                  // Mentioned Users Preview
                  // حذف یا عدم نمایش ویرایشگر کاربران منشن‌شده
                  // if (mentionedUsers.isNotEmpty)
                  //   SizedBox(
                  //     height: 50,
                  //     child: ListView.builder(
                  //       scrollDirection: Axis.horizontal,
                  //       itemCount: mentionedUsers.length,
                  //       itemBuilder: (context, index) {
                  //         final user = mentionedUsers[index];
                  //         return Padding(
                  //           padding: const EdgeInsets.symmetric(horizontal: 4),
                  //           child: Chip(
                  //             avatar: CircleAvatar(
                  //               backgroundImage: user.avatarUrl != null
                  //                   ? NetworkImage(user.avatarUrl!)
                  //                       as ImageProvider
                  //                   : null,
                  //             ),
                  //             label: Text(user.username),
                  //             onDeleted: () {
                  //               setState(() {
                  //                 mentionedUsers.removeAt(index);
                  //               });
                  //             },
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ),

                  // Mention and Comment Input
                  Directionality(
                    textDirection: getDirectionality(commentController.text),
                    child: TextField(
                      controller: commentController,
                      focusNode: commentFocusNode,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'کامنت خود را بنویسید...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _sendComment(context, ref, postId,
                              commentController, mentionedUsers),
                        ),
                      ),
                      onChanged: (value) {
                        // Mention detection logic
                        _handleMentionSearch(
                            ref, value, setState, mentionedUsers);
                      },
                    ),
                  ),

                  // Mention Suggestions
                  Consumer(
                    builder: (context, ref, _) {
                      final mentionUsers = ref.watch(mentionNotifierProvider);
                      return mentionUsers.isNotEmpty
                          ? _buildMentionSuggestions(context, mentionUsers,
                              setState, commentController, mentionedUsers)
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// Mention Search Handler
void _handleMentionSearch(WidgetRef ref, String value, StateSetter setState,
    List<UserModel> mentionedUsers) {
  if (value.contains('@')) {
    final mentionPart = value.split('@').last;
    if (mentionPart.isNotEmpty) {
      ref
          .read(mentionNotifierProvider.notifier)
          .searchMentionableUsers(mentionPart);
    }
  } else {
    ref.read(mentionNotifierProvider.notifier).clearMentions();
  }
}

// Mention Suggestions Widget
Widget _buildMentionSuggestions(
  BuildContext context,
  List<UserModel> mentionUsers,
  StateSetter setState,
  TextEditingController commentController,
  List<UserModel> mentionedUsers,
) {
  return SizedBox(
    height: 100,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: mentionUsers.length,
      itemBuilder: (context, index) {
        final user = mentionUsers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () {
              // Add mention to comment
              _addMentionToComment(
                  commentController, user, setState, mentionedUsers);
            },
            child: Chip(
              avatar: CircleAvatar(
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                    : AssetImage(defaultAvatarUrl),
              ),
              label: Text(user.username),
            ),
          ),
        );
      },
    ),
  );
}

// Add Mention to Comment
void _addMentionToComment(
  TextEditingController commentController,
  UserModel user,
  StateSetter setState,
  List<UserModel> mentionedUsers,
) {
  final currentText = commentController.text;
  final mentionPart = currentText.split('@').last;
  final newText =
      currentText.replaceFirst('@$mentionPart', '@${user.username} ');

  commentController.text = newText;
  commentController.selection =
      TextSelection.fromPosition(TextPosition(offset: newText.length));

  setState(() {
    if (!mentionedUsers.any((u) => u.id == user.id)) {
      final mentionedUsersSet = <UserModel>{};
      mentionedUsersSet.add(user);
      mentionedUsers.clear();
      mentionedUsers.addAll(mentionedUsersSet);
    }
  });
}

// Send Comment Method
void _sendComment(
  BuildContext context,
  WidgetRef ref,
  String postId,
  TextEditingController commentController,
  List<UserModel> mentionedUsers,
) async {
  final content = commentController.text.trim();
  final mentionedUserIds = mentionedUsers.map((user) => user.id).toList();

  if (content.isNotEmpty) {
    try {
      await ref
          .read(commentNotifierProvider.notifier)
          .addComment(
            postId: postId,
            content: content, // محتوای کامل کامنت
            mentionedUserIds: mentionedUserIds,
          )
          .then((value) {
        commentController.clear();
        mentionedUsers.clear();
      });

      ref.read(mentionNotifierProvider.notifier).clearMentions();
      ref.invalidate(commentsProvider(postId));
    } catch (e) {
      print('خطا در ارسال کامنت: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ارسال کامنت: $e')),
      );
    }
  }
}

// Comments List Widget
Widget _buildCommentsList(BuildContext context, WidgetRef ref,
    List<CommentModel> comments, String userId) {
  return ListView.builder(
    reverse: true,
    itemCount: comments.length,
    itemBuilder: (context, index) {
      final comment = comments[index];
      return _buildCommentTile(context, ref, comment, userId);
    },
  );
}

Widget _buildCommentTile(BuildContext context, WidgetRef ref,
    CommentModel comment, String currentUserId) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Hero(
        tag: 'avatar_${comment.id}',
        child: CircleAvatar(
          radius: 25,
          backgroundImage: comment.avatarUrl != null
              ? NetworkImage(comment.avatarUrl!)
              : null,
          child: comment.avatarUrl == null
              ? Icon(
                  Icons.person,
                  color: isDarkMode ? Colors.white : Colors.black,
                )
              : null,
        ),
      ),
      title: Text(
        comment.username,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Directionality(
          textDirection: getDirectionality(comment.content),
          child: RichText(
            text: TextSpan(
              children: _buildCommentTextSpans(comment, isDarkMode, context),
            ),
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatCommentTime(comment.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'گزارش تخلف') {
                  await _showReportDialog(context, ref, comment, currentUserId);
                } else if (value == 'حذف کامنت') {
                  await _showDeleteConfirmationDialog(context, ref, comment)
                      .then((value) =>
                          ref.invalidate(commentsProvider(comment.postId)));
                }
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<String>> menuItems = [
                  const PopupMenuItem<String>(
                    value: 'گزارش تخلف',
                    child: Text('گزارش تخلف'),
                  )
                ];

                if (comment.userId == currentUserId) {
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: 'حذف کامنت',
                      child: Text('حذف'),
                    ),
                  );
                }

                return menuItems;
              },
            ),
          ],
        )
      ]));
}

// تابع نمایش دیالوگ گزارش
Future<void> _showReportDialog(BuildContext context, WidgetRef ref,
    CommentModel comment, String currentUserId) async {
  String selectedReason = '';
  TextEditingController additionalDetailsController = TextEditingController();

  final confirmed = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: const Text('گزارش تخلف'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('لطفاً دلیل گزارش را انتخاب کنید:'),
                  ...[
                    'محتوای نامناسب',
                    'هرزنگاری',
                    'توهین آمیز',
                    'اسپم',
                    'محتوای تبلیغاتی',
                    'سایر موارد'
                  ].map((reason) {
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                    );
                  }),
                  if (selectedReason == 'سایر موارد')
                    TextField(
                      controller: additionalDetailsController,
                      decoration: const InputDecoration(
                        hintText: 'جزئیات بیشتر را وارد کنید',
                      ),
                      maxLines: 3,
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                ),
                child: const Text('لغو'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                child: const Text('گزارش'),
                onPressed: () {
                  if (selectedReason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً دلیل گزارش را انتخاب کنید'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed == true) {
    try {
      await ref.read(reportCommentServiceProvider).reportComment(
            commentId: comment.id,
            reporterId: currentUserId,
            reason: selectedReason,
            additionalDetails: selectedReason == 'سایر موارد'
                ? additionalDetailsController.text.trim()
                : null,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کامنت با موفقیت گزارش شد.'),
        ),
      );
    } catch (e) {
      print('خطا در گزارش تخلف: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در گزارش کامنت.'),
        ),
      );
    }
  }
}

// تابع نمایش دیالوگ حذف
Future<void> _showDeleteConfirmationDialog(
    BuildContext context, WidgetRef ref, CommentModel comment) async {
  final confirmDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('حذف'),
      content: Text('آیا از حذف این کامنت اطمینان دارید؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'انصراف',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'حذف',
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800]),
          ),
        ),
      ],
    ),
  );

  if (confirmDelete == true) {
    try {
      // حذف کامنت با استفاده از provider
      await ref
          .read(commentNotifierProvider.notifier)
          .deleteComment(comment.id, ref);

      // نمایش پیام موفقیت
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کامنت با موفقیت حذف شد.'),
        ),
      );
    } catch (e) {
      // نمایش خطا در صورت شکست حذف
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در حذف کامنت.'),
        ),
      );
    }
  }
}

// Parse comment text to handle mentions
List<TextSpan> _buildCommentTextSpans(
    CommentModel comment, bool isDarkMode, BuildContext context) {
  final List<TextSpan> spans = [];
  final mentionRegex = RegExp(r'@(\w+)');

  final matches = mentionRegex.allMatches(comment.content);
  int lastIndex = 0;

  for (final match in matches) {
    // متن قبل از منشن
    if (match.start > lastIndex) {
      spans.add(
        TextSpan(
          text: comment.content.substring(lastIndex, match.start),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      );
    }

    // استایل منشن
    spans.add(
      TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: Colors.blue.shade400,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final username = match.group(1); // استخراج نام کاربری
            if (username != null) {
              // دریافت userId از پایگاه داده یا API بر اساس username
              final userId = await getUserIdByUsername(username);
              if (userId != null) {
                // ناوبری به پروفایل کاربر
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      username: username,
                      userId: userId,
                    ),
                  ),
                );
              }
            }
          },
      ),
    );

    lastIndex = match.end;
  }

  // متن باقی مانده
  if (lastIndex < comment.content.length) {
    spans.add(
      TextSpan(
        text: comment.content.substring(lastIndex),
        style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87, fontSize: 15),
      ),
    );
  }

  return spans;
}

// یک متد برای جلب userId از پایگاه داده بر اساس username
Future<String?> getUserIdByUsername(String username) async {
  // فرض کنید از Supabase برای جلب userId استفاده می‌کنید
  final response = await supabase
      .from('profiles')
      .select('id')
      .eq('username', username)
      .single();

  if (response != null && response['id'] != null) {
    return response['id'];
  } else {
    return null; // اگر کاربر یافت نشد
  }
}

// Delete Comment Method
void _deleteComment(BuildContext context, WidgetRef ref, String commentId,
    String postId) async {
  try {
    await ref
        .read(commentNotifierProvider.notifier)
        .deleteComment(commentId, ref);

    // Optional: Refresh comments list
    ref.invalidate(commentsProvider(postId));

    // Optional: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('کامنت با موفقیت حذف شد')),
    );
  } catch (e) {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطا در حذف کامنت: $e')),
    );
  }
}

// Report Comment Method
void _reportComment(BuildContext context, CommentModel comment) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('گزارش تخلف'),
      content: TextField(
        decoration: InputDecoration(
          hintText: 'دلیل گزارش را توضیح دهید',
        ),
        maxLines: 3,
        onChanged: (reason) {
          // You can implement reporting logic here
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () {
            // Implement report submission
            Navigator.pop(context);
          },
          child: Text('ثبت گزارش'),
        ),
      ],
    ),
  );
}

// Time formatting utility
String _formatCommentTime(DateTime createdAt) {
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inMinutes < 1) {
    return 'همین الان';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes} دقیقه پیش';
  } else if (difference.inDays < 1) {
    return '${difference.inHours} ساعت پیش';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} روز پیش';
  } else {
    return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
  }
}

//report profile dialog
class ReportProfileDialog extends StatefulWidget {
  final String userId; // شناسه پروفایل کاربری که قرار است گزارش شود

  const ReportProfileDialog({super.key, required this.userId});

  @override
  _ReportProfileDialogState createState() => _ReportProfileDialogState();
}

class _ReportProfileDialogState extends State<ReportProfileDialog> {
  String selectedReason = '';
  TextEditingController additionalDetailsController = TextEditingController();

  final List<String> reportReasons = [
    'محتوای نامناسب',
    'هرزنگاری',
    'توهین آمیز',
    'اسپم',
    'محتوای تبلیغاتی',
    'سایر موارد',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('گزارش تخلف'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لطفاً دلیل گزارش را انتخاب کنید:'),
            ...reportReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: selectedReason,
                onChanged: (String? value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              );
            }),
            if (selectedReason == 'سایر موارد')
              TextField(
                controller: additionalDetailsController,
                decoration: const InputDecoration(
                  hintText: 'جزئیات بیشتر را وارد کنید',
                ),
                maxLines: 3,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('لغو'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Consumer(
          builder: (context, ref, child) => TextButton(
            child: const Text('گزارش'),
            onPressed: () async {
              if (selectedReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لطفاً دلیل گزارش را انتخاب کنید'),
                  ),
                );
                return;
              }

              try {
                await ref.read(reportProfileServiceProvider).reportProfile(
                      userId: widget.userId,
                      reporterId: ref.read(authProvider)?.id ?? '',
                      reason: selectedReason,
                      additionalDetails:
                          additionalDetailsController.text.isEmpty
                              ? null
                              : additionalDetailsController.text,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('پروفایل با موفقیت گزارش شد.'),
                  ),
                );
              } catch (e) {
                print('خطا در گزارش پروفایل: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('خطا در گزارش پروفایل.'),
                  ),
                );
              }

              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
