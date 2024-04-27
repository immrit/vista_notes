import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../View/Screens/Home.dart';
import '../View/Screens/LoginScreen.dart';

final pb = PocketBase('http://10.0.2.2:8089');

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
    await pb.collection('users').authWithPassword(
          username,
          password,
        );
    RecordModel recordModel;
    recordModel = pb.authStore.model;
    User user = User.fromRecordModel(recordModel);
    print(user.username);
    print(pb.authStore.model);
    // var usermodel=
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Home(
                  username: user.username,
                )));
  } catch (e) {}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class User {
  String username;
  String email;
  List expand;

  User({required this.username, required this.email, required this.expand});
  factory User.fromRecordModel(RecordModel recordModel) {
    Map<String, dynamic> json = recordModel.toJson();
    return User(
        username: json['username'] ?? "",
        email: json['email'] ?? "",
        expand: json['expand'] ?? "");
  }
  Map<String, dynamic> toJson() {
    return {'username': username, "email": email, "expand": expand};
  }

  // factory User.fromJson(Map<String, dynamic> json) {
  //   return User(
  //     username: json['username'] ?? "",
  //     email: json['email'] ?? "",
  //   );
  // }
}
