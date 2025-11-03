//this is a modal for the users_savedRoutes


import 'package:flutter/material.dart';
// import 'package:testing/main.dart';

class SavedRoutes extends StatefulWidget{
  final String? route;

  const SavedRoutes({super.key, this.route});

  @override
  State<SavedRoutes> createState() => _SavedRoutesState();
}

class _SavedRoutesState extends State<SavedRoutes>{
int index = 0;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child:  CustomScrollView(
          slivers: [
            SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
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
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'You', 
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.route),
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
                  Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(70, 95, 95, 95),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add),
                              
                                  SizedBox(width: 10,),
                                  //make this tappable add GestureDetector
                                  Text(
                                    'Add Route', style: 
                                    TextStyle(
                                      
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
      
      
                      ),
      
                      SizedBox(height: 14),
      
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Your Saved Routes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold
                              ),
                            ),
                      ),
      
                      SizedBox(height: 14),
                      
                      ...List.generate(
                        20, 
                        (index) => Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 15),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(148, 158, 158, 158),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('${widget.route} #${index + 1}'),
                              ),
                            ),
                          ),
                        )
                        
      
                ]),
              ),
              )
            
          ],
        ),

    );
    
    
    
  }

}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}