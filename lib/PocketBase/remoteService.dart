import 'package:pocketbase/pocketbase.dart';

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
