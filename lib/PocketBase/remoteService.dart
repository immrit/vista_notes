import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../View/Screens/Home.dart';

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
    await pb.collection('users').authWithPassword(
          username,
          password,
        );

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Home()));
  } catch (e) {
    print(e);
  }
}

Future<void> addNotes(String title, String description) async {
  final body = <String, dynamic>{
    "title": title,
    "description": description,
    "user": pb.authStore.model.id,
  };

  final record = await pb.collection('notes').create(body: body);

  print(record);
}

class User {
  String username;
  String email;

  User({
    required this.username,
    required this.email,
  });
  factory User.fromRecordModel(RecordModel recordModel) {
    Map<String, dynamic> json = recordModel.toJson();

    return User(
      username: json['username'] ?? "",
      email: json['email'] ?? "",
    );
  }
}

class NoteClass {
  String title;
  String description;
  String userID;
  NoteClass(
      {required this.title, required this.description, required this.userID});

  factory NoteClass.fromRecordModel(RecordModel noteModel) {
    Map<String, dynamic> json = noteModel.toJson();

    return NoteClass(
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      userID: json['user'] ?? "",
    );
  }
}

// class HiveGetData {
//   static Box<UserModel> getUserModel() => Hive.box<UserModel>('userBox');
// }
