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
  @override
  Widget build(BuildContext context) {
    var _loading = true;
    final TextEditingController titleController = TextEditingController();
    Future<void> _insertPost() async {
      setState(() {
        _loading = true;
      });
      final title = titleController.text.trim();
      final user = supabase.auth.currentUser;
      final updates = {
        'id': user!.id,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Notes'),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            const UserAccountsDrawerHeader(
              accountName: Text('نام کاربری'),
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
      body: const Column(
        children: [],
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
                        _insertPost();
                        Navigator.pop(context);
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
