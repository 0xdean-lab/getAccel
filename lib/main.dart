import 'package:flutter/material.dart';
import 'screens/recordScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recording Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecordScreen(),
    );
  }
}
