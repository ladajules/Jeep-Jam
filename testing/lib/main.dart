import 'package:flutter/material.dart';
import 'package:testing/pages/introduction_page.dart';
import 'package:testing/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingPage1(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/intropage': (context) => const OnboardingPage1(),
        '/homepage': (context) => const HomePage(),
      }
    );
  }

}


