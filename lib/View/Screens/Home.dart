import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vista_notes/Model/Hive%20Model/userModel.dart';
import 'package:vista_notes/View/Screens/CreateNote.dart';
import 'package:vista_notes/View/Screens/LoginScreen.dart';

import '../../PocketBase/remoteService.dart';

class Home extends StatefulWidget {
  Home({Key? key, this.userModel}) : super(key: key);

  final UserModel? userModel;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var jsonList;

  late UserModel _model;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    Future.delayed(Duration(minutes: 1)).then((value) => getData());
  }

  @override
  void initState() {
    super.initState();
    getData();
    // if (widget.userModel != null) {
    //   _model = widget.userModel!;
    // } else {
    //   _model = UserModel(username: '', email: '', token: '');
    //   getUserData();
    // }
  }

  // getUserData() async {
  //   final box = HiveGetData.getUserModel();
  //   var userData = box.get('user');
  //   if (userData != null) {
  //     setState(() {
  //       _model = userData;
  //     });
  //   } else {
  //     print('user data is null');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: IconButton(
          onPressed: () {
            setState(() {});
          },
          icon: const Icon(
            Icons.refresh,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.remove('token');
                pb.authStore.clear();
                print('prefs.remove');
                print(pb.authStore.token);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              },
              icon: const Icon(Icons.power))
        ],
      ),
      body: Container(
        child: Center(
            child: ListView.builder(
                itemCount: jsonList == null ? 0 : jsonList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      children: [
                        Text(jsonList[index]['title']),
                        Text(jsonList[index]['description']),
                      ],
                    ),
                  );
                })),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => CreateNote()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  getData() async {
    try {
      Map<String, dynamic> q = {
        'filter': 'user.id="${pb.authStore.model.id}"',
        'sort': '-updated'
      };
      var response = await Dio().get(
          'http://10.0.2.2:8090/api/collections/notes/records',
          queryParameters: q);
      if (response.statusCode == 200) {
        setState(() {
          jsonList = response.data['items'];
          //Save Data TO HiveDB

          // RecordModel recordModel = pb.authStore.model;
          // User user = User.fromRecordModel(recordModel);
          // var usermodel = UserModel(
          //     username: user.username,
          //     email: user.email,
          //     token: pb.authStore.token);
          // final box = HiveGetData.getUserModel();
          // box.put('user', usermodel);

          //END Save
          // print(response);
        });
      }
      print(jsonList);
      return response.data['items']
          .map<NoteClass>((e) => NoteClass.fromRecordModel(e))
          .toList();
    } catch (e) {
      print(e);
    }
  }
}
