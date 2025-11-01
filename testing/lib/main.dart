import 'package:flutter/material.dart';
import 'package:testing/pages/introduction_page.dart';
import 'package:testing/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // load environtment variables

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

class TutorialPage extends StatefulWidget{
  const TutorialPage({
    super.key
  });

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>{
  @override
  void initState(){
    super.initState();
    _checkFirstTime();
  }

  Future <void> _checkFirstTime() async{
    final prefs = await SharedPreferences.getInstance();
    bool? hasSeenTutorial = prefs.getBool('SeenTutorial');

    if (!mounted) return; // to check if the widget is still within the tree

    if (hasSeenTutorial == true){
      Navigator.pushReplacementNamed(context, '/homepage');
    } else {
      Navigator.pushReplacementNamed(context, '/introduction_page');
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator()),
    );
  }
}

