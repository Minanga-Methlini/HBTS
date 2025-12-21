import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'admin/dashboard.dart';
import 'admin/home.dart';

void main() {
  runApp(const HBTSApp());
}

class HBTSApp extends StatelessWidget {
  const HBTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HBTS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
