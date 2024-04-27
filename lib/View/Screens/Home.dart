import 'package:flutter/material.dart';
import 'package:vista_notes/View/Screens/LoginScreen.dart';

import '../../PocketBase/remoteService.dart';

class Home extends StatefulWidget {
  Home({Key? key, required this.username}) : super(key: key);

  String username;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Container(
        child: Center(
          child: Column(
            children: [
              Text(widget.username),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()));
                    });
                  },
                  child: Text("refresh"))
            ],
          ),
        ),
      ),
    );
  }
}
