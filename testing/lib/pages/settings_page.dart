import 'package:flutter/material.dart';
import 'package:testing/services/auth.dart';
import 'package:testing/widgets/auth_gate.dart';
import '../controllers/navigation_manager.dart';
import '../widgets/bottom_nav_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int currentIndex = 3;
  final NavigationManager nav = NavigationManager();
  final Auth _auth = Auth();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings Page',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            ),

              
            IconButton(
              onPressed: () async {
                await _auth.signOut();
                if (context.mounted){
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false, // This removes all previous routes
                  );
                }
              }, 
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              color: Colors.red,
              ),
          ],
        )
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