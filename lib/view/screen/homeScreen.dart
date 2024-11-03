import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vistaNote/view/screen/Notes/NotesPage.dart';
import 'package:vistaNote/view/screen/support.dart';
import '../../main.dart';
import '../../util/widgets.dart';
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
        ref.watch(publicPostsProvider); // پرووایدر پست‌ها
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);
    // صفحات برای هر تب
    final List<Widget> tabs = [
      const NotesScreen(), // صفحه یادداشت‌ها
      const PublicPostsScreen(), // صفحه پست‌های عمومی
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista Notes"),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(createSearchPageRoute());
          },
          icon: const Icon(Icons.search),
        ),
      ),
      endDrawer: Drawer(
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
                      accountName: Text(
                        '${getprofile['username']}',
                        style: TextStyle(
                            color: currentcolor.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                      ),
                      accountEmail: Text("${supabase.auth.currentUser!.email}",
                          style: TextStyle(
                              color: currentcolor.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)),
                    );
                  },
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator())),
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SupportPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text(
                'دعوت از دوستان',
              ),
              onTap: () {
                const String inviteText =
                    'دوست عزیز سلام! من از ویستا نوت برای ذخیره یادداشت هام استفاده میکنم! \n امکانات این نرم افزار بی نظیره میتونی از این لینک از طریق مایکت دانلودش کنی:  https://myket.ir/app/com.example.vista_notes2 ';
                Share.share(inviteText);
              },
            ),
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
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'یادداشت‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'کافه ویستا',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
