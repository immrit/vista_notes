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
    @override
    void initState() {
      ref.refresh(profileProvider);
    }

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
                        backgroundImage:
                            NetworkImage(getprofile!['avatar_url'].toString()),
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
            Container(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text(
                  'حساب کاربری',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // به صفحه پروفایل بروید
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text(
                'پشتیبانی',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                //   supabase.auth.signOut();
                //
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SupportPage()));
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
              height: he < 685 ? 350.h : 400.h,
            ),
            const Text(
              'Version: 1.1.0',
              style: TextStyle(color: Colors.white60),
            )
          ],
        ),
      ),
      body: notesAsyncValue.when(
        data: (notes) => RefreshIndicator(
          onRefresh: () async {
            ref.refresh(notesProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: notes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final note = notes[index];
                return GestureDetector(
                  onLongPress: () {
                    showCustomBottomSheet(context, note, () {
                      ref.read(deleteNoteProvider(note.id));
                      ref.refresh(notesProvider);
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
                    // کد مربوط به ویرایش را اینجا قرار دهید
                  },
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListTile(
                        title: Text(
                          note.title,
                          softWrap: true,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazir'),
                        ),
                        subtitle: Text(
                          note.content,
                          softWrap: true,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white54, fontFamily: 'Vazir'),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
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
