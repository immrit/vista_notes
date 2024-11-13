import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vistaNote/view/screen/Notes/NotesPage.dart';
import 'package:vistaNote/view/screen/support.dart';
import '../../main.dart';
import '../../util/widgets.dart';
import 'PublicPosts/notificationScreen.dart';
import 'PublicPosts/publicPosts.dart';
import '../../provider/provider.dart'; // پرووایدرها

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesProvider);
    final publicPostsAsyncValue =
        ref.watch(fetchPublicPosts); // پرووایدر پست‌ها

    // صفحات برای هر تب
    final List<Widget> tabs = [
      const NotesScreen(), // صفحه یادداشت‌ها
      PublicPostsScreen(), // صفحه پست‌های عمومی
      NotificationsPage()
    ];

    return Scaffold(
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'یادداشت‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'کافه ویستا',
          ),
          BottomNavigationBarItem(
            label: 'اعلان ها',
            icon: Icon(Icons.favorite),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
