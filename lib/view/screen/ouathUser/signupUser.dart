import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({Key? key}) : super(key: key);

  @override
  _SignupUserState createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  signup() async {
    final AuthResponse res = await supabase.auth.signUp(
      email: 'example@email.com',
      password: 'example-password',
    );
    final Session? session = res.session;
    final User? user = res.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Scaffold(
        body: Container(
          child: ElevatedButton(
            child: Text("Signup"),
            onPressed: () => signup,
          ),
        ),
      ),
    );
  }
}
