import 'package:flutter/material.dart';
import 'package:vista_notes2/util/constant.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.amber,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Home",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    client.auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/main', (rute) => false);
                  },
                  child: Text("signout")),
            ],
          ),
        ),
      ),
    );
  }
}
