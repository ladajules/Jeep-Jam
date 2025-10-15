import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Function for the bottom nav bar
  void _navigationBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of pages for the bottom nav bar
  // final List<Widget> _pages = [
  //   TestingHomePage(),
  //   TestingMapPage(),
  //   TestingSavedroutesPage(),
  //   TestingSettingsPage(),
  // ];

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/jeeplogo.png'),
                width: 150,
              ),

              SizedBox(height: 20),

              Text(
                'Welcome to Jeep Jam!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'Travel with Confidence', 
                style: TextStyle(
                  fontSize: 18,
                ),
              ),

            ],
          ),

        ),

        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xff6200ee),
          unselectedItemColor: const Color(0xff757575),
          onTap: _navigationBottomBar,
          items: _navBarItems,
        ),

      );
  }
}

final _navBarItems = [
  SalomonBottomBarItem(
    icon: const Icon(Icons.home),
    title: const Text("Home"),
    selectedColor: Colors.purple,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.favorite_border),
    title: const Text("Map"),
    selectedColor: Colors.orange,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.search),
    title: const Text("Saved Routes"),
    selectedColor: Colors.blue,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.person),
    title: const Text("Settings"),
    selectedColor: Colors.teal,
  ),
];