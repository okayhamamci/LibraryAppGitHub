import 'package:flutter/material.dart';
import 'package:library_frontend/library_home.dart';
import 'package:library_frontend/start_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Application',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const StartPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
