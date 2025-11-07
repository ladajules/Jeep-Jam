import 'package:flutter/material.dart';
import '../controllers/navigation_manager.dart';
import '../widgets/bottom_nav_bar.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({super.key});

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  int currentIndex = 1;
  final NavigationManager nav = NavigationManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Activity',
          style: TextStyle(
            fontSize: 30,
          ),
        ),
      ),

      bottomNavigationBar: JeepJamBottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          nav.navigate(context, index); 
        },
      ),
    );
  }
}