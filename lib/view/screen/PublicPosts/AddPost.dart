import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
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
    final content = contentController.text;
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
      await supabase.from('public_posts').insert({
        'content': content,
        'user_id': Supabase.instance.client.auth.currentSession!.user.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(publicPostsProvider);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن پست عمومی جدید'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'محتوای پست',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addPost,
                    child: const Text('افزودن پست'),
                  ),
          ],
        ),
      ),
    );
  }
}
