import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class JeepJamBottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const JeepJamBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<JeepJamBottomNavbar> createState() => _JeepJamBottomNavbarState();
}

class _JeepJamBottomNavbarState extends State<JeepJamBottomNavbar> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xffde7d4c),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: SalomonBottomBar(
        currentIndex: widget.currentIndex,
        selectedItemColor: const Color(0xff6200ee),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        onTap: widget.onTap,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
            selectedColor: Color(0xff6e2d1b),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.assignment_rounded),
            title: const Text("Activity"),
            selectedColor: Color(0xff6e2d1b),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.bookmark),
            title: const Text("Saved"),
            selectedColor: Color(0xff6e2d1b),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text("Account"),
            selectedColor: Color(0xff6e2d1b),
          ),
        ],
      ),
    );
  }
}

