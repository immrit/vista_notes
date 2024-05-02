import 'dart:convert';

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
    await pb.collection('users').authWithPassword(
          username,
          password,
          expand: 'notes',
        );
    RecordModel recordModel;
    recordModel = pb.authStore.model;
    User user = User.fromRecordModel(recordModel);
    // print(pb.authStore.model);
    print('@@@@@@@@@@');
    print(user.title);

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Home(
                  title: user.title,
                  description: user.description.toList(),
                )));
  } catch (e) {
    print(e);
  }
}

class User {
  String username;
  String email;
  dynamic title;
  dynamic description;

  User({
    required this.username,
    required this.email,
    required this.title,
    required this.description,
  });
  factory User.fromRecordModel(RecordModel recordModel) {
    Map<String, dynamic> json = recordModel.toJson();
    List<String> title = [];
    List<String> description = [];

    if (json['expand']['notes'][0]['title'] != null &&
        json['expand']['notes'][0] != null) {
      json['expand']['notes'].forEach((expandItem) {
        title.add(expandItem['title']);
        description.add(expandItem['description']);
        // print(expandItem[0]['title']);
      });
    }
    return User(
        username: json['username'] ?? "",
        email: json['email'] ?? "",
        // title: json['expand']['notes'][0]['title'] ?? "",
        title: title,
        description: description);
  }
}
