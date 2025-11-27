


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/pages/home_page.dart';
import 'package:testing/pages/introduction_page.dart';
import 'package:testing/pages/login_register_page.dart';
import 'package:testing/services/auth.dart';

const String kSeenTutorialKey = 'SeenTutorial';

Future<bool> _getTutorialStatus() async{
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kSeenTutorialKey) ?? false;
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});



  @override
  Widget build(BuildContext context) {
    final Auth auth = Auth();

    return StreamBuilder(
      stream: auth.authStateChanges, 
      builder: (context, snapshot){
        if (snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        

        if (snapshot.hasData){
        
          return  FutureBuilder<bool>(
            future: _getTutorialStatus(),
            builder: (context, tutorialSnapshot) {
              if (tutorialSnapshot.connectionState == ConnectionState.waiting){
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final hasSeenTutorial = tutorialSnapshot.data ?? false;

              if (hasSeenTutorial){
                return const HomePage();
              } else {
                return const OnboardingPage1();
              }
            }
          );
        }

        return const LoginRegisterPage();
      }
      );

  }
}