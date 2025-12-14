import 'package:flutter/material.dart';

void showCenterModalHowToRead(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // SingleChildScrollView prevents overflow on smaller screens if text wraps
        child: SingleChildScrollView( 
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFFEF1D8),
              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.brown, width : 3.0,)
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Expanded(
                      child: Text(
                        'How To Read Jeepney Codes?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), 
                    // IconButton(
                    //   padding: EdgeInsets.zero, 
                    //   constraints: const BoxConstraints(), 
                    //   icon: const Icon(Icons.close),
                    //   onPressed: () => Navigator.pop(context),
                    // ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Jeepney codes (usually seen on the front, side, or back) are short alphanumeric tags that correspond to a specific route.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),

                const Text(
                  'The Format:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E2D1B),
                  ),
                ),
                const SizedBox(height: 8),

                // Bullet Points
                const Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            'The Number: Represents the general area or route origin (e.g., "04" or "13").',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            'The Letter: Represents the specific loop, terminal, or destination variation (e.g., "C" for Carbon, "L" for Lahug).',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            'Example: "17B" usually runs from Apas to Carbon via Jones.',
                            style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6E2D1B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Got It!',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}