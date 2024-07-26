import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista_notes2/util/constant.dart';
import 'package:vista_notes2/view/screen/ouathUser/welcome.dart';

import '../../main.dart';
import '../../util/widgets.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<dynamic> notes = []; // لیست برای ذخیره نت ها
  String username = '';
  var _loading = true;
  final TextEditingController titleController = TextEditingController();

  Future<void> _getNotes() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data = await supabase.from('Notes').select().eq('user_id', userId);
      setState(() {
        notes = data; // نت ها را در لیست ذخیره می کنیم
      });
    } on PostgrestException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _insertNote() async {
    setState(() {
      _loading = true;
    });
    final title = titleController.text.trim();
    final user = supabase.auth.currentUser;
    final updates = {
      'user_id': user!.id,
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('Notes').insert(updates);
      if (mounted) context.showSnackBar('Successfully updated profile!');
    } on PostgrestException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _getprofileData() async {
    try {
      final userID = supabase.auth.currentSession!.user.id;
      final data =
          await supabase.from('profiles').select().eq('id', userID).single();
      setState(() {
        username = data['username'].toString();
        print(username);
      });
    } catch (e) {
      print(e);
    }
  }

  initState() {
    super.initState();
    _getNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Notes'),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text('${username}'),
              accountEmail: Text('ایمیل کاربری'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.brown,
                child: Text('N'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('پروفایل'),
              onTap: () {
                // به صفحه پروفایل بروید
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('خروج'),
              onTap: () {
                client.auth.signOut();

                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? CircularProgressIndicator()
          : ListView.builder(
              itemCount: notes.length, // تعداد نت ها
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notes[index]['title']), // نمایش عنوان نت
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _insertNote().then((v) => _getNotes());

                          Navigator.pop(context);
                        });
                      },
                      child: const Text('post'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
