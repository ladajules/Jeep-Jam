import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

Widget buildPlaceCard(Map<String, dynamic> place) {
  Logger logger = Logger();
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: InkWell(
      onTap: () {
        logger.i('Place tapped: ${place['location']}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xffdea855),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(164, 158, 158, 158),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon or image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color.fromARGB(87, 110, 45, 27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.place,
                color: Color(0xff6e2d1b),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            
            // Place details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['location'] ?? 'Unknown Place',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    ),
  );
}