import 'package:flutter/material.dart';
import 'package:vista_notes/View/Screens/LoginScreen.dart';

import '../../PocketBase/remoteService.dart';

class Home extends StatefulWidget {
  Home({super.key, required this.title, required this.description});

  List title;
  List description;

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
            child: ListView.builder(
                itemCount: widget.title.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      children: [
                        Text(widget.title[index].toString()),
                        Text(widget.description[index]),
                      ],
                    ),
                  );
                })),
      ),
    );
  }
}
