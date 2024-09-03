import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                        decoration: BoxDecoration(color: Colors.grey[800]),
                        accountName: Text('${getprofile!['username']}'),
                        accountEmail:
                            Text("${supabase.auth.currentUser!.email}"),
                      );
                    },
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
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
                  // به صفحه پروفایل بروید
                  Navigator.pushNamed(context, '/profile');
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

                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              SizedBox(
                height: he < 685 ? 410.h : 480.h,
              ),
              Text(
                'dev 0.0.1 ${he.toString()}',
                style: const TextStyle(color: Colors.white60),
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
                      showCustomBottomSheet(context, note);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                          title: Text(
                        note.title,
                        style: const TextStyle(color: Colors.white),
                      )),
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
              Text('دسترسی به اینترنت قطع است :('),
              IconButton(
                  iconSize: 50.h,
                  splashColor: Colors.transparent,
                  color: Colors.white,
                  onPressed: () {
                    ref.refresh(notesProvider);
                    ref.refresh(profileProvider);
                  },
                  icon: Icon(Icons.refresh))
            ],
          )),
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white,
            child: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AddNoteScreen()));
            }));
  }
}
