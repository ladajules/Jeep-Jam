import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/pages/home_page.dart';
import 'package:testing/pages/introduction_page.dart';
import 'package:testing/pages/login_register_page.dart';
import 'package:testing/pages/verify_email.dart';
import 'package:testing/services/auth.dart';
import 'package:testing/services/firebase_service.dart';
import '../pages/admin_page.dart';

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
    final FirebaseService _firebaseService = FirebaseService();

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
          final User user = snapshot.data!;

          if (!user.emailVerified){
            return const EmailVerificationPage();
          }

<<<<<<< HEAD
          // check if user is admin then go to admin page
          return FutureBuilder<bool>(
            future: _firebaseService.isUserAdmin(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
=======
          return  FutureBuilder<bool>(
            future: _getTutorialStatus(),
            builder: (context, tutorialSnapshot) {
              if (tutorialSnapshot.connectionState == ConnectionState.waiting){
>>>>>>> 80b93e2cc5d3554ce626d7155d98bb6540659139
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(),),
                );
              }

              final isAdmin = adminSnapshot.data ?? false;

              if (isAdmin) {
                return const AdminPage();
              }

              // else if user, check tutorial status
              return FutureBuilder<bool>(
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
                },
              );
            },
          );
        }

        return const LoginRegisterPage();
      }
    );
  }
}