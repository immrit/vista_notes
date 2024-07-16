import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vista_notes2/util/constant.dart';

class Loginuser extends StatefulWidget {
  const Loginuser({Key? key}) : super(key: key);

  @override
  _LoginuserState createState() => _LoginuserState();
}

class _LoginuserState extends State<Loginuser> {
  final TextEditingController username = TextEditingController();
  final TextEditingController pass = TextEditingController();
  bool isloading = false;

  Future<void> login(final email, final pass) async {
    setState(() {
      isloading = true;
    });
    try {
      await client.auth.signInWithPassword(password: pass, email: email);
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("error"),
      ));
    }
    setState(() {
      isloading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    username.dispose();
    pass.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                topText(
                  text: '!خوش برگشتی',
                ),
                const SizedBox(height: 80),
                customTextField('نام کاربری'),
                SizedBox(height: 10),
                customTextField('رمزعبور'),

//button

                Padding(
                  padding: const EdgeInsets.only(top: 400),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                        onPressed: () async {
                          login(username.text, pass.text);
                        },
                        child: const Text("login")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget customTextField(String hintText) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextFormField(
          controller: username,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white60),
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.amber,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class topText extends StatelessWidget {
  String text;
  topText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 15),
        child: Text(
          '${text}',
          style: TextStyle(
              fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
