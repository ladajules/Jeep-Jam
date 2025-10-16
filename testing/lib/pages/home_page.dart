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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image(
              //   image: AssetImage('assets/jeeplogo.png'),
              //   width: 150,
              // ),
          
              // SizedBox(height: 20),
          
            Text(
              'Current Location',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                
              ),
            ),
          
            Text(
              'addres placeholder',
              style: TextStyle(
                fontSize: 15,
                
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(
                    'Im the map that shows the current loc',
                    style: TextStyle(
                      fontSize: 20,
                      color: const Color.fromARGB(255, 0, 0, 0)
                    ),
                   ),
                 ],
               ),
              ),
            ),
              // Text(
              //   'Travel with Confidence', 
              //   style: TextStyle(
              //     fontSize: 18,
              //   ),
              // ),
          
            Padding(
              padding: const EdgeInsets.only(top: 7.0),
              child: Container(
                width: double.infinity,
                height: 240,
                // decoration: BoxDecoration(
                //   color: Colors.grey,
                //   borderRadius: BorderRadius.all(Radius.circular(10)),
                // ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Hows the weather?', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(12))
                      ),
                      child: Center(
                        child: Text(
                          'weather api here!',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                  ],
                ),

                

              ),
            )


            ],
          ),
          
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