import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class NavigationManager {
  final logger = Logger();

  void navigate(BuildContext context, index) {
    switch (index) {
      case 0:
      logger.i("Home page tapped. Redirecting to home page...");
      Navigator.pushReplacementNamed(context, '/homepage');
      break;

      case 1:
      logger.i('Activity page tapped. Redirecting to activity page...');
      Navigator.pushReplacementNamed(context, "/activitypage");
      break;

      case 2:
      logger.i("Saved routes page tapped. Redirecting to saved routes page...");
      Navigator.pushReplacementNamed(context, "/savedroutespage");
      break;

      case 3:
      logger.i("Profile page tapped. Redirecting to settings page...");
      Navigator.pushReplacementNamed(context, "/profilepage");
      break;
    }
  }
}