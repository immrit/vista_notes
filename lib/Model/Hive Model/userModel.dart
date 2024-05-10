import 'package:hive_flutter/hive_flutter.dart';

part 'userModel.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String username;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String token;
  UserModel({
    required this.username,
    required this.email,
    required this.token,
  });
}
