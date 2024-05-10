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
    // RecordModel recordModel = pb.authStore.model;
    // User user = User.fromRecordModel(recordModel);
    // var usermodel = UserModel(
    //   username: user.username,
    //   email: user.email,
    //   token: user.token,
    // );
    storeuserID() async {
      final prefsToken = await SharedPreferences.getInstance();
      prefsToken.setString('userID', pb.authStore.model.id);
    }

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

// Future<List<RecordModel>?>? getnotes() async {
//   final notesColl = await pb.collection('notes').getList(
//         filter: 'user.id="${pb.authStore.model.id}"',
//         page: 1,
//         perPage: 50,
//       );
//   print(notesColl);
// }

class User {
  String username;
  String email;
  String token;

  User({
    required this.username,
    required this.email,
    required this.token,
  });
  factory User.fromRecordModel(RecordModel recordModel) {
    Map<String, dynamic> json = recordModel.toJson();

    return User(
        username: json['username'] ?? "",
        email: json['email'] ?? "",
        token: json['token'] ?? "");
  }
}

class NoteClass {
  String title;
  String description;
  NoteClass({
    required this.title,
    required this.description,
  });

  factory NoteClass.fromRecordModel(RecordModel noteModel) {
    Map<String, dynamic> json = noteModel.toJson();

    return NoteClass(
      title: json['title'] ?? "",
      description: json['description'] ?? "",
    );
  }
}

// class HiveGetData {
//   static Box<UserModel> getUserModel() => Hive.box<UserModel>('userBox');
// }
