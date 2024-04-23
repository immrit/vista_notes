import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget TextInputWidget(
    TextEditingController controller, String hintText, bool obscureText) {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20, bottom: 10),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25))),
    ),
  );
}

Widget VistaTextLogo() {
  return Text("Vista Notes",
      style: TextStyle(fontFamily: "Bauhaus", fontSize: 50));
}

Widget LoginAndSignUpButton() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: () {},
      child: const Text("ورود",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          )),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
      ),
    ),
  );
}
