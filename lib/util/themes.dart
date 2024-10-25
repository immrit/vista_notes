import 'package:flutter/material.dart';

// تم روشن
final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue[400],
    appBarTheme: const AppBarTheme(color: Colors.transparent),
    fontFamily: 'Vazir',
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.white60));

// تم تاریک
final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    fontFamily: 'Vazir',
    primaryColor: Colors.grey[800],
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.blueGrey));

// تم سفارشی
final ThemeData customTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    fontFamily: 'Vazir',
    appBarTheme: AppBarTheme(color: Colors.red[200]),
    primaryColor: Colors.red,
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(backgroundColor: Colors.red[400]));
