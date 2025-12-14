import 'package:flutter/material.dart';

Future<dynamic>_showAboutJeepJam(BuildContext context) {
 return showDialog(
    context: context,
    builder: (BuildContext context) {
    
      final double screenHeight = MediaQuery.of(context).size.height;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                 color: const Color(0xFFFEF1D8),
                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: Colors.brown, width : 3.0,)

                
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'About Jeep Jam',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  const Text(
                    'Jeep Jam addresses the common problem that many commuters in Cebu are unfamiliar with specific jeepney routes. This often results in commuters having to ask the driver or conductor if their destination is en route. The app aims to solve this by unifying and documenting jeepney routes to help you Travel with Confidence.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Who Benefits from Jeep Jam?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Benefits List
                  _buildBenefitSection('Students', 'Allows young commuters to readily check jeepney routes and codes that will take them to and from school, leveraging the ubiquity of the smartphone.'),
                  const SizedBox(height: 15),
                  _buildBenefitSection('Young Workforce', 'Assists those entering the workforce in navigating unfamiliar routes to institutions of higher education or their workplace.'),
                  const SizedBox(height: 15),
                  _buildBenefitSection('Tourists', 'Provides prompt, focused, and accessible services to visitors in Cebu who are less likely to be familiar with the public transportation routes and codes due to a lack of documentation.'),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<dynamic>_showMeetDevelopers(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      // 1. Get screen height
      final double screenHeight = MediaQuery.of(context).size.height;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          // 2. Apply height constraint
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF1D8),
                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: Colors.brown, width: 3.0,),
              ),
              
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "JeepJam's Developers",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Developer 1
                  _buildDeveloperSection('Jules Lada', 'A 2nd year IT student from the University of San Carlos.'),
                  const SizedBox(height: 20),

                  // Developer 2
                  _buildDeveloperSection('Gaea Mutia', 'A 2nd year IT student from the University of San Carlos.'),
                  const SizedBox(height: 20),

                  // Developer 3
                  _buildDeveloperSection('Althea Telmo', 'A 2nd year IT student from the University of San Carlos.'),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Helper Widget for Developer Sections
Widget _buildDeveloperSection(String name, String description) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6E2D1B),),
      ),
      const SizedBox(height: 4),
      Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
    ],
  );
}

// Helper Widget for Benefit Sections
Widget _buildBenefitSection(String title, String description) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6E2D1B),),
      ),
      const SizedBox(height: 4),
      Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
    ],
  );
}

void showCenterModalHowToLearn(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF1D8), // Beige Background
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learn More About Us',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6E2D1B), 
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 40), 

              // Icon Grid/Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Option 1: JeepJam Info
                  GestureDetector(
                    onTap: () {
                      // LOGIC CHANGE: We DO NOT close this modal.
                      // We just open the next one on top of it.
                      _showAboutJeepJam(context); 
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.info, size: 80, color: Colors.black),
                        SizedBox(height: 10),
                        Text(
                          'JeepJam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6E2D1B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Option 2: Developers Info
                  GestureDetector(
                    onTap: () {
                      // LOGIC CHANGE: We DO NOT close this modal.
                      // We just open the next one on top of it.
                      _showMeetDevelopers(context);
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.people_alt, size: 80, color: Colors.black), 
                        SizedBox(height: 10),
                        Text(
                          'Developers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6E2D1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}