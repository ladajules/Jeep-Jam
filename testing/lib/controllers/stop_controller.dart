import 'package:flutter/material.dart';

class StopController {
  final TextEditingController nameController;
  final TextEditingController latController;
  final TextEditingController lngController;

  StopController({
    String name = '',
    String lat = '',
    String lng = '',
  })  : nameController = TextEditingController(text: name),
        latController = TextEditingController(text: lat),
        lngController = TextEditingController(text: lng);

  void dispose() {
    nameController.dispose();
    latController.dispose();
    lngController.dispose();
  }
}