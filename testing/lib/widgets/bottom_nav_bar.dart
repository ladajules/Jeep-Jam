import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class JeepJamBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const JeepJamBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SalomonBottomBar(
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xff6200ee),
        unselectedItemColor: const Color(0xff757575),
        onTap: onTap,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.bookmark),
            title: const Text("Saved"),
            selectedColor: Colors.blue,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.settings),
            title: const Text("Settings"),
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}