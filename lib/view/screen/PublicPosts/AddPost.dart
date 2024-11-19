import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// اضافه شده
import 'package:vistaNote/util/widgets.dart';
import '../../../provider/provider.dart';

class AddPublicPostScreen extends ConsumerStatefulWidget {
  const AddPublicPostScreen({super.key});

  @override
  _AddPublicPostScreenState createState() => _AddPublicPostScreenState();
}

class _AddPublicPostScreenState extends ConsumerState<AddPublicPostScreen> {
  final TextEditingController contentController = TextEditingController();
  bool isLoading = false;

  Future<void> _addPost() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً محتوای پست را وارد کنید.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) {
        throw Exception('خطا در شناسایی کاربر.');
      }

      await Supabase.instance.client.from('public_posts').insert({
        'content': content,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(fetchPublicPosts);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پست با موفقیت اضافه شد!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در افزودن پست: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پست جدید'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                addNotesTextFiels(
                  'هرچه میخواهی بگو...',
                  50,
                  contentController,
                  18,
                  FontWeight.normal,
                  1000,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 10,
            right: 10),
        child: SizedBox(
          height: 50,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: isLoading ? null : _addPost,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(10, 50),
                backgroundColor: currentColor.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'افزودن پست',
                      style: TextStyle(
                        color: currentColor.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazir',
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
