import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vistaNote/main.dart';
import 'package:vistaNote/view/screen/Notes/NotesPage.dart';
import 'PublicPosts/notificationScreen.dart';
import 'PublicPosts/profileScreen.dart';
import 'PublicPosts/publicPosts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  // لیست صفحات
  final List<Widget> _tabs = [
    const NotesScreen(), // صفحه یادداشت‌ها
    const PublicPostsScreen(), // صفحه پست‌های عمومی
    const NotificationsPage(), // صفحه اعلان‌ها
    ProfileScreen(
      userId: supabase.auth.currentUser!.id,
    )
  ];

  // هندل کردن تغییر تب
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'یادداشت‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes),
            label: 'کافه ویستا',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'اعلان‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_2_outlined),
            selectedIcon: Icon(Icons.person_2),
            label: 'حساب کاربری',
          ),
        ],
        elevation: 3,
        animationDuration: const Duration(milliseconds: 500),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
