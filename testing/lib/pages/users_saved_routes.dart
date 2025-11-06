//this is a modal for the users_savedRoutes

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:testing/widgets/sticky_header_delegate.dart';

class SavedRoutesPage extends StatefulWidget{
  final String? route;
  final VoidCallback? onBack;

  const SavedRoutesPage({super.key, this.route, this.onBack});

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesState();
}

class _SavedRoutesState extends State<SavedRoutesPage>{
  int index = 0;
  final logger = Logger();
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
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
                        'You', 
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                            logger.i('Closed button tapped on the Saved Routes Page. Redirecting to home...');
                              widget.onBack?.call();
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
        ),
      ],
    );
  }
}

