import 'package:android_launcher/screens/home_screen.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:installed_apps/installed_apps.dart';
// ignore: unused_import
import 'package:installed_apps/app_info.dart';
// ignore: unused_import
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deep Launcher',
      home: HomeScreen(),
    );
  }
}
