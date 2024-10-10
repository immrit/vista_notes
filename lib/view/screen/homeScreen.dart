import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vistaNote/view/screen/support.dart';
import '../../main.dart';
import '../../provider/provider.dart';
import '../../util/widgets.dart';
import 'AddNoteScreen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofile = ref.watch(profileProvider);
    final notesAsyncValue = ref.watch(notesProvider);

    final he = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Color(Colors.black12.value),
        title: const Text(
          "Vista Notes",
          style: TextStyle(color: Colors.white),
        ),
      ),
      endDrawer: Drawer(
        backgroundColor: Color(Colors.grey[900]!.value),
        width: 0.6.sw,
        child: Column(
          children: <Widget>[
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: getprofile.when(
                  data: (getprofile) {
                    return UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(
                          color: Colors.grey,
                          image: DecorationImage(
                              image:
                                  AssetImage('lib/util/images/headerBack.jpg'),
                              fit: BoxFit.cover)),
                      currentAccountPicture: CircleAvatar(
                        radius: 30,
                        backgroundImage: getprofile!['avatar_url'] != null
                            ? NetworkImage(getprofile['avatar_url'].toString())
                            : const AssetImage(
                                'lib/util/images/default-avatar.jpg'),
                      ),
                      margin: const EdgeInsets.only(bottom: 0),
                      currentAccountPictureSize: const Size(65, 65),
                      accountName: Text('${getprofile['username']}'),
                      accountEmail: Text("${supabase.auth.currentUser!.email}"),
                    );
                  },
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator())),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                'حساب کاربری',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text(
                'پشتیبانی',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SupportPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'خروج',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                supabase.auth.signOut();
                Navigator.pushReplacementNamed(context, '/welcome');
              },
            ),
            SizedBox(
              height: he < 685 ? 220 : 398,
            ),
            const Text(
              'Version: 1.1.0',
              style: TextStyle(color: Colors.white60),
            )
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: notesAsyncValue.when(
          data: (notes) {
            final pinnedNotes = notes.where((note) => note.isPinned).toList();
            final otherNotes = notes.where((note) => !note.isPinned).toList();

            pinnedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            otherNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(notesProvider);
                ref.refresh(profileProvider);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: [
                    if (pinnedNotes.isNotEmpty) ...[
                      const Text(
                        'پین شده ها:',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      NoteGridWidget(notes: pinnedNotes, ref: ref),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'سایر یادداشت‌ها:',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    NoteGridWidget(notes: otherNotes, ref: ref),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('دسترسی به اینترنت قطع است :('),
              IconButton(
                  iconSize: 50.h,
                  splashColor: Colors.transparent,
                  color: Colors.white,
                  onPressed: () {
                    ref.refresh(notesProvider);
                    ref.refresh(profileProvider);
                  },
                  icon: const Icon(Icons.refresh))
            ],
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: const Icon(Icons.edit),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddNoteScreen()));
          }),
    );
  }
}
