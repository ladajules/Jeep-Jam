import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// pages
import 'package:testing/pages/introduction_page.dart';
import 'package:testing/pages/home_page.dart';
import 'package:testing/pages/login_register_page.dart';
import 'package:testing/pages/recent_activity_page.dart';
import 'package:testing/pages/users_saved_routes.dart';
import 'package:testing/pages/settings_page.dart';
import 'package:testing/pages/directions_page.dart';
import 'package:testing/widgets/auth_gate.dart';
import 'package:testing/pages/forget_pass.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // load environtment variables

  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/loginregisterpage' : (context) => const LoginRegisterPage(),
        '/intropage': (context) => const OnboardingPage1(),
        '/homepage': (context) => const HomePage(),
        '/directionspage': (context) => const DirectionsPage(),
        '/savedroutespage': (context) => const SavedRoutesPage(),
        '/settingspage': (context) => const SettingsPage(),
        '/activitypage': (context) => const RecentActivityPage(),
        '/forgotpass' : (context) => const ForgotPassword(),
      }
    );
  }
}

// class TutorialPage extends StatefulWidget{
//   const TutorialPage({
//     super.key
//   });

//   @override
//   State<TutorialPage> createState() => _TutorialPageState();
// }

// class _TutorialPageState extends State<TutorialPage>{
//   @override
//   void initState(){
//     super.initState();
//     _checkFirstTime();
//   }

//   Future <void> _checkFirstTime() async{
//     final prefs = await SharedPreferences.getInstance();
//     bool? hasSeenTutorial = prefs.getBool('SeenTutorial');

//     if (!mounted) return; // to check if the widget is still within the tree

//     if (hasSeenTutorial == true){
//       Navigator.pushReplacementNamed(context, '/homepage');
//     } else {
//       Navigator.pushReplacementNamed(context, '/intropage');
//     } 
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: CircularProgressIndicator()),
//     );
//   }
// }

