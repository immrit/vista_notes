import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../View/Screens/Home.dart';
import '../View/Screens/LoginScreen.dart';

final pb = PocketBase('http://10.0.2.2:8090');

Future<void> SignUpUserRemote(String username, String email, String password,
    String passwordConfirm) async {
  final body = <String, dynamic>{
    'username': username,
    "email": email,
    "password": password,
    "passwordConfirm": passwordConfirm,
  };
  final record = await pb.collection('users').create(body: body);
  print(record);
}

Future<void> LoginUserRemote(
    String username, String password, BuildContext context) async {
  try {
    await pb.collection('users').authWithPassword(username, password);
    RecordModel recordModel;
    recordModel = pb.authStore.model;
    User user = User.fromRecordModel(recordModel);
    // print(user.username);
    print(pb.authStore.model);
    // var usermodel=
    List tst = [];
    user.notes.forEach((element) {
      tst.add(element['notes']);
    });
    print('objectobjectobjectobject');
    print(tst);

    final record = await pb.collection('notes').getOne(
          "zdtba4sgz82mt2f",
          expand: 'title,description',
        );

    print('~~~~~~~~~~~~~~~~~~');
    print(record);

    print('objectobjecctobjectobjectojectobjectobjectobject');
    print(user.notes);
    // print(pb.authStore.model.notes);

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Home(
                  username: user.notes.toString(),
                )));
  } catch (e) {
    print(e);
  }
}

// Future<void> getnotes() async {
//   try {
//     User user=
//     final record = await pb.collection('notes').getOne(,
//   expand: 'relField1,relField2.subRelField',
// );
//   } catch (e) {
//     print(e);
//   }
// }

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class User {
  String username;
  String email;
  List notes;

  User({
    required this.username,
    required this.email,
    required this.notes,
  });
  factory User.fromRecordModel(RecordModel recordModel) {
    Map<String, dynamic> json = recordModel.toJson();
    return User(
        username: json['username'] ?? "",
        email: json['email'] ?? "",
        notes: json['notes'] ?? "");
  }
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      "email": email,
    };
  }

  // factory User.fromJson(Map<String, dynamic> json) {
  //   return User(
  //     username: json['username'] ?? "",
  //     email: json['email'] ?? "",
  //   );
  // }
}
