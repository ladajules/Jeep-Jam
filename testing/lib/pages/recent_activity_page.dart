import 'package:flutter/material.dart';
import 'package:testing/widgets/sticky_header_delegate.dart';
import '../controllers/navigation_manager.dart';
import '../widgets/bottom_nav_bar.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({super.key});
  
  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  int currentIndex = 1;
  final int totalTrips = 5; //hardcoded

  final NavigationManager nav = NavigationManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyHeaderDelegate(
                minHeight: 60,
                maxHeight: 60,
                child: Container(
                  color: Colors.white,  // Add background
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 4),  // Reduced margin
                        width: 40,
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Activity', 
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => currentIndex = 0);
                                nav.navigate(context, 0); 
                              },
                              child: Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ),
          
            SliverPadding(
              padding: EdgeInsets.all(0.8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                
                  SizedBox(height: 14),
          
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('This Week',
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          ),
                        ),
                  ),
          
                  SizedBox(height: 14),

                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: Colors.black,
                  //     borderRadius: BorderRadius.circular(12)
                  //   ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(108, 128, 127, 127),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: 
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Trips:'
                                  ),
                                  SizedBox(height: 5),

                                  Text(
                                    '$totalTrips'
                                  )
                                ],
                              ),


                              Column(
                                children: [
                                  Text(
                                    'Total Time:'
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'time time'
                                  )
                                ],
                              ),
                                              
                              Column(
                                children: [
                                  Text(
                                    'Top Route: '
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '13i'
                                  )
                                ],
                              ),
                            ],
                          ),
                      
                          
                        ),
                      ),
                    ),
                  
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Recent Trips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          ),
                        ),
                  ),
                      
                  ...List.generate(totalTrips, 
                  (index) => Padding(
                    padding: 
                    EdgeInsets.all(9),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(148, 158, 158, 158),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('wow')
                        ],
                      ),
                        
                    ),
                    )
                  ),

                ]
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: JeepJamBottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          nav.navigate(context, index); 
        },
      ),
    );
  }
}