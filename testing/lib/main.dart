import 'package:flutter/material.dart';
import 'package:testing/IntroductionPage.dart';

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
    );
  }

}


