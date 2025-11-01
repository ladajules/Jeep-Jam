import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:testing/services/weather_service.dart';
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
  // weather weather lang
  final _weatherService = WeatherService('8495ebbd64085ce1548343ab7d374f9b');
  Weather ? _weather;

  _fetchWeather() async{
    String cityName = await _locationService.getCurrentCity();

    try{
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    }

    catch(e){
      print("unable to fetch weather");
    }
  }


    @override
    void initState(){
      super.initState;
      _getLocationAndAddress();
      _fetchWeather();
    }

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

  String getWeatherIcon (String? mainCondition){
    if (mainCondition == null){
      return 'assets/weather_icons/sunny.json';
    }

    switch(mainCondition.toLowerCase()){
       case 'clouds':
      return 'assets/weather_icons/windy.json';

      case 'rain':
      return 'assets/weather_icons/rain.json';

      case 'thunderstorm':
      return 'assets/weather_icons/thunderstorm.json';

      case 'clear':
      return 'assets/weather_icons/sunny.json';

      default:
      return 'assets/weather_icons/windy.json';
    }
  }

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
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Sticky header with drag handle
                SliverPersistentHeader(
                  pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 100,
                  maxHeight: 100,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Drag Handle
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
                        // Header Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
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

                              GestureDetector(
                                onTap: (){
                                  //show detailzzzzz
                                },

                                child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(48, 192, 191, 191),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Lottie.asset(getWeatherIcon(_weather?.mainCondition),
                                        width: 30,  
                                        height: 30,
                                        fit: BoxFit.contain, 
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_weather?.temperature.round() ?? '--'}℃',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _weather?.mainCondition ?? "Loading....", style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          )
                                        ),

                                        
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              )
                              
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          
          // Scrollable content
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                      // Text(
                      //   'current loc (try, this is working btw i think)',
                      //   style: TextStyle(
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.red,
                      //   ),
                      // ),
                      SizedBox(height: 8),
                      Text(
                        _currentAddress != null 
                            ? '${_currentAddress!.street}, ${_currentAddress!.locality}' 
                            : 'off ang location or permission denied',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
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
                // Scrollable items
                ...List.generate(
                  10,
                  (index) => Padding(
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
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  },
)


  ],
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

  //bottom_sheet_modal -> make error page and info page zzz
  //wrap the weatherContainer with gestureDetector -> done 