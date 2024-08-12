import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../main.dart';
import '../../provider/provider.dart';
import '../../util/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getprofile = ref.watch(profileProvider);
    final notesAsyncValue = ref.watch(notesProvider);

    return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Color(Colors.black12.value),
          title: Text(
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
                  'پروفایل',
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
                height: .53.sh,
              ),
              Text(
                'dev 0.0.1',
                style: TextStyle(color: Colors.white60),
              )
            ],
          ),
        ),
        body: notesAsyncValue.when(
          data: (notes) => GridView.builder(
            itemCount: notes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                    title: Text(
                  note.title,
                  style: const TextStyle(color: Colors.white),
                )),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          showMyDialog(context);
        }));
  }
}

// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:vista_notes2/util/constant.dart';
// import 'package:vista_notes2/view/screen/ouathUser/welcome.dart';

// import '../../main.dart';
// import '../../util/widgets.dart';

// class Homescreen extends StatefulWidget {
//   const Homescreen({super.key});

//   @override
//   State<Homescreen> createState() => _HomescreenState();
// }

// class _HomescreenState extends State<Homescreen> {
//   List<dynamic> notes = []; // لیست برای ذخیره نت ها
//   String? username;
//   var _loading = true;
//   final TextEditingController titleController = TextEditingController();

// Future<void> _getNotes() async {
//   setState(() {
//     _loading = true;
//   });

//   try {
//     final userId = supabase.auth.currentSession!.user.id;
//     final data = await supabase.from('Notes').select().eq('user_id', userId);
//     setState(() {
//       notes = data; // نت ها را در لیست ذخیره می کنیم
//     });
//   } on PostgrestException catch (error) {
//     if (mounted) context.showSnackBar(error.message, isError: true);
//   } catch (error) {
//     if (mounted) {
//       context.showSnackBar('Unexpected error occurred', isError: true);
//     }
//   } finally {
//     if (mounted) {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }
// }

//   Future<void> _insertNote() async {
//     setState(() {
//       _loading = true;
//     });
//     final title = titleController.text.trim();
//     final user = supabase.auth.currentUser;
//     final updates = {
//       'user_id': user!.id,
//       'title': title,
//       'created_at': DateTime.now().toIso8601String(),
//     };
//     try {
//       await supabase.from('Notes').insert(updates);
//       if (mounted) context.showSnackBar('Successfully updated profile!');
//     } on PostgrestException catch (error) {
//       if (mounted) context.showSnackBar(error.message, isError: true);
//     } catch (error) {
//       if (mounted) {
//         context.showSnackBar('Unexpected error occurred', isError: true);
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//     }
//   }

//   Future<void> _getprofileData() async {
//     try {
//       final userID = supabase.auth.currentSession!.user.id;
//       final data =
//           await supabase.from('profiles').select().eq('id', userID).single();
//       setState(() {
//         username = data['username'].toString();
//         print(username);
//       });
//     } catch (e) {
//       print(e);
//     }
//   }

//   initState() {
//     super.initState();
//     _getNotes();
//     _getprofileData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userID = supabase.auth.currentSession!.user.id;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Vista Notes'),
//       ),
//       endDrawer: Drawer(
//         child: ListView(
//           children: <Widget>[
//             UserAccountsDrawerHeader(
//               accountName: Text('${this.username} '),
//               accountEmail: Text('${supabase.auth.currentSession!.user.email}'),
//               currentAccountPicture: CircleAvatar(
//                 backgroundColor: Colors.brown,
//                 child: Text('N'),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('پروفایل'),
//               onTap: () {
//                 // به صفحه پروفایل بروید
//                 Navigator.pushNamed(context, '/prof');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('خروج'),
//               onTap: () {
//                 client.auth.signOut();

//                 Navigator.pushReplacementNamed(context, '/login');
//               },
//             ),
//           ],
//         ),
//       ),
//       body: _loading
//           ? CircularProgressIndicator()
//           : ListView.builder(
//               itemCount: notes.length, // تعداد نت ها
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(notes[index]['title']), // نمایش عنوان نت
//                 );
//               },
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showDialog<String>(
//             context: context,
//             builder: (BuildContext context) => Dialog(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     TextField(
//                       controller: titleController,
//                     ),
//                     const SizedBox(height: 15),
//                     TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _insertNote().then((v) => _getNotes());

//                           Navigator.pop(context);
//                         });
//                       },
//                       child: const Text('post'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

