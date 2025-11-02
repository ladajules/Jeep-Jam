import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:testing/services/weather_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
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
  double _sheetPosition = 0.25;
  final logger = Logger(); // e = error; i = info msg; w = warning msg; d = debug msg

  // Google Maps
  GoogleMapController? _mapController;
  Set<maps.Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.2926, 123.9022),
    zoom: 14,
  );

  // weather weather lang
  late WeatherService _weatherService;
  Weather? _weather;

    @override
    void initState(){
      super.initState();

      final weatherApiKey = dotenv.env['OPENWEATHER_API_KEY'];
      _weatherService = WeatherService(weatherApiKey!);

      _getLocationAndAddress();
      _fetchWeather();  

      _scrollController.addListener(() {
        if (_scrollController.isAttached) {
          setState(() {
            _sheetPosition = _scrollController.size;
          });
        }
      });
    }

  Future<void> _fetchWeather() async {
    String cityName = await _locationService.getCurrentCity();

    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    }

    catch(e) {
      logger.e("unable to fetch weather");
    }
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

    if (_mapController != null) {
      final LatLng userLocation = LatLng(position.latitude, position.longitude);

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:userLocation,
            zoom: 15,
          ),
        ),
      );

      setState(() {
        _markers = {
          maps.Marker(
            markerId: MarkerId('user_location'),
            position: userLocation,
            infoWindow: InfoWindow(
              title: 'Your Location',
              snippet: placemark != null ? '${placemark.street}, ${placemark.locality}' : '',
            ),
          ),
        };
      });
    }
  }

  // List of pages for the bottom nav bar
  // final List<Widget> _pages = [
  //   TestingHomePage(),
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentPosition != null) {
      final LatLng userLocation = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude
      );

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLocation,
            zoom: 15,
          ),
        ),
      );
    }
  }

  // make the buttons follow along the draggable sheet (not functional yet)
  double _calculateButtonPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.5;
    final currentSheetHeight = screenHeight * _sheetPosition;

    if (_sheetPosition <= 0.5) {
      return currentSheetHeight + 16;
    } else {
      return maxSheetHeight + 16;
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: Stack(
          children: [
            // Gogol maps
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPosition,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              //liteModeEnabled: true, // once naa najuy gogol maps, ill try erasing this
            ),

            // da buttons
            Positioned(
              right: 16,
              bottom: _calculateButtonPosition(),
              child: Column(
                children: [
                  // explore button 
                  FloatingActionButton(
                    onPressed: () {
                      logger.i('Explore button pressed. Centering the center point to make it center so it would be at the center, middle of the map...');
                      // some function that centers the thingyy, i saw it somewhere sa YT
                    },
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 15),

                  // directions button
                  FloatingActionButton(
                    onPressed: () {
                      logger.i('Direction button pressed. Redirecting to directions page... chaaar');
                      //Navigator.pushNamed(context, '/soon to open nga page');
                    },
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: Icon(
                      Icons.directions,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ],
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
                  color: const Color.fromARGB(50, 0, 0, 0),
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
                                    showMaterialModalBottomSheet(
                                      
                                      expand: false,
                                      context: context, 
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => FractionallySizedBox(
                                        heightFactor: 0.4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(50, 0, 0, 0),
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              offset: Offset(0, -2),
                                            ),
                                            ]
                                          ),
                                          
                                          child: WeatherScreen(
                                            weather: _weather,
                                            position: _currentPosition,
                                            placemark: _currentAddress,
                                          ),
                                        ),
                                      )

                                    );
                                  
                                  
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
                                      child: _weather != null ? Lottie.asset(getWeatherIcon(_weather?.mainCondition),
                                        width: 30,  
                                        height: 30,
                                        fit: BoxFit.contain, 
                                      )
                                      : 
                                      const Text('error'),
                                    ),

                                    SizedBox(height: 4),

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
                                    ),
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
                  15,
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
),


  ],
), 

        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: SalomonBottomBar(
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xff6200ee),
              unselectedItemColor: const Color(0xff757575),
              onTap: _navigationBottomBar,
              items: _navBarItems,
          ),
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
    icon: const Icon(Icons.bookmark),
    title: const Text("Saved"),
    selectedColor: Colors.blue,
  ),
  SalomonBottomBarItem(
    icon: const Icon(Icons.settings),
    title: const Text("Settings"),
    selectedColor: Colors.teal,
  ),
];

class WeatherScreen extends StatefulWidget {
  final Weather? weather;
  final Position? position;
  final Placemark? placemark;

  const WeatherScreen({
    super.key,
    required this.weather,
    required this.position,
    required this.placemark
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>{
  @override
  Widget build(BuildContext context){
    final hasError = widget.weather == null || widget.position == null;

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


    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: hasError //ternary for which build to show
        ?
        Column( //shows this if weather or location is error
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 7),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),
            Text(
              'An error occured. Try again later!', style: TextStyle(
                fontSize: 24,
                color: Colors.black 
              ),
            ),
    
            SizedBox(height: 20),      
            Lottie.asset('assets/LoadingFiles.json'),
      
            SizedBox(height: 20),  
            Text('Wait wait wait!! jeep jam will fix things!', style: 
              TextStyle(
                fontSize: 18,
                color: Colors.black)
                )
          ],
        )
        
        : //if it returns valid information it returns weather weather lang
        Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 7),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),
            Text('Weather in the area',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(getWeatherIcon(widget.weather?.mainCondition),
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain
                  ),
                  
                  Text('  ${widget.weather?.temperature.round()}°C', 
                  style: TextStyle(
                    fontSize: 50,
                  ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
        
              Text('${widget.weather?.description}',
              style: TextStyle(
                fontSize: 16
              ),
              ),

              SizedBox(width: 20),  //spacing

              Text('Feels like: ${widget.weather?.feelsLike.round()}°',
              style: TextStyle(
                fontSize: 16
              ),),

              SizedBox(width: 20),  //spacing
        
              Text('Humidity: ${widget.weather?.humidity}',
              style: TextStyle(
                fontSize: 16
              ),),
            ],)
        
          ],
        )

      ),
    );
  }

}