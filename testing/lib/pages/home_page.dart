import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  Placemark? _currentAddress;
  String _status = "No location yet yo";
  final DraggableScrollableController _scrollController = DraggableScrollableController();

  // Function for the bottom nav bar
  void _navigationBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //Function for geolocator
  Future<void> _getLocationAndAddress() async {
    setState(() => _status = "Fetching location...");

    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      setState(() => _status = "Location permission denied or service off.");
      return;
    }

    final placemark = await _locationService.getAddressFromCoordinates(position);

    setState(() {
      _currentPosition = position;
      _currentAddress = placemark;
      _status = placemark != null ? "Location fetched successfully!" : "Failed to get address";
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
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Color(0xFFB3E5FC),
              child: Center(
                child: Text(
                  'Maps will be here (temporary)',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.9,
              controller: _scrollController,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),

                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Learn more',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),

                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'weather here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),

                                ),

                              ],
                            ),
                            SizedBox(height: 16),

                            Center(
                              child: Text(
                                'stuff will go here',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 13),

                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'current loc (try, this is working btw i think)',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 8),

                                  Text(
                                    _currentAddress != null ? '${_currentAddress!.street}, ${_currentAddress!.locality}' : 'off ang location or permission denied',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),

                                  // CAN DELETE THIS, JUST FOR DEBUG PURPOSES
                                  Text( 
                                    _status,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // this just to show nga you can put as many stuff as you want and ma scrollable siyaa so chuyy right!!
                            ...List.generate(10, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('Item ${index + 1}'),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // child: SafeArea(child: Column(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     // Image(
          //     //   image: AssetImage('assets/jeeplogo.png'),
          //     //   width: 150,
          //     // ),
          
          //     // SizedBox(height: 20),
          
          //   Text(
          //     'Current Location',
          //     textAlign: TextAlign.left,
          //     style: TextStyle(
          //       color: Colors.black,
          //       fontSize: 16,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          
          //   Text(
          //     _status, // CAN DELETE, just for debug purposes
          //     style: TextStyle(
          //       fontSize: 15,
                
          //     ),
          //   ),
            
          //   Padding(
          //     padding: const EdgeInsets.only(top: 14.0),
          //     child: Container(
          //       width: double.infinity,
          //       height: 160,
          //       decoration: BoxDecoration(
          //         color: Colors.grey,
          //         borderRadius: BorderRadius.all(Radius.circular(12)),
          //       ),
          //      child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //        children: [
          //          Text(
          //           'Im the map that shows the current loc',
          //           style: TextStyle(
          //             fontSize: 20,
          //             color: const Color.fromARGB(255, 0, 0, 0)
          //           ),
          //          ),
          //        ],
          //      ),
          //     ),
          //   ),
          //     // Text(
          //     //   'Travel with Confidence', 
          //     //   style: TextStyle(
          //     //     fontSize: 18,
          //     //   ),
          //     // ),
          
          //   Padding(
          //     padding: const EdgeInsets.only(top: 7.0),
          //     child: Container(
          //       width: double.infinity,
          //       height: 240,
          //       // decoration: BoxDecoration(
          //       //   color: Colors.grey,
          //       //   borderRadius: BorderRadius.all(Radius.circular(10)),
          //       // ),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Padding(
          //             padding: const EdgeInsets.all(8.0),
          //             child: Text(
          //               'Hows the weather?', 
          //               style: TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //           ),
          //           Container(
          //             width: double.infinity,
          //             height: 150,
          //             decoration: BoxDecoration(
          //               color: Colors.grey,
          //               borderRadius: BorderRadius.all(Radius.circular(12))
          //             ),
          //             child: Center(
          //               child: Text(
          //                 'weather api here!',
          //                 style: TextStyle(
          //                   fontSize: 20,
          //                 ),
          //               ),
          //             ),
          //           )
          //         ],
          //       ),

                

          //     ),
          //   ),

          //   ],
          // ),
          
          // ),
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



class WeatherModel{
  final String condition;
  final double temperature;

  WeatherModel({
    required this.condition,
    required this.temperature
  });
}

class PopularRouteModel{
  final String destination;
  final List<String> jeepneyCodes;

  PopularRouteModel({
    required this.destination,
    required this.jeepneyCodes,
  });
}

class GuideModel{
  final String title;
  final String description;

  GuideModel({
    required this.title,
    required this.description,
  });
}