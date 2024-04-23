import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8089');

Future<void> SignUpUserRemote() async {
  final body = <String, dynamic>{
    'username': 'ahmad',
    "email": "bob@example.com",
    "password": "12345678",
    "passwordConfirm": "12345678",
    "name": "Bob Smith"
  };
  final record = await pb.collection('users').create(body: body);
  print(record);
}
