import 'package:flutter/material.dart';
import 'package:text2speech/viewpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'DL Hackathon',
      home: MainPage(),
    );
  }
}