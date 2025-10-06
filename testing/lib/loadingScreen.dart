
import 'package:flutter/material.dart';

class LoadingScreenMats extends StatelessWidget{
  const LoadingScreenMats({super.key});
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center( 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(image: AssetImage('assets/jeeplogo.png')),
          const Text('Jeep Jam',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),),
          const Text('Travel with Confidence', 
          style: TextStyle(
            fontSize: 18,
          ),),
        ],
      ),
    ),
  );
  }
}

