// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:testing/services/firebase_service.dart';
import 'package:testing/utils/build_divider.dart';
import 'package:testing/widgets/show_center_modal_learn.dart';
import 'package:testing/widgets/show_center_modal_read.dart';

// useful shizzles
import '../services/location.dart';
import '../services/weather_service.dart';
import '../controllers/map_manager.dart';
import '../controllers/navigation_manager.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_screen.dart';
import '../widgets/sticky_header_delegate.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/place_card_utils.dart';


class HomePage extends StatefulWidget /*with AutomaticKeepAliveClientMixin*/ {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
  //bool get wantKeepAlive => true;
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0; // for navbar

  final LocationService _locationService = LocationService();
  // weather weather lang
  late WeatherService _weatherService;
  final MapManager _mapManager = MapManager();
  final NavigationManager nav = NavigationManager();
  final logger = Logger(); // e = error; i = info msg; w = warning msg; d = debug msg
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingSuggested = false;
  List<Map<String, dynamic>> _suggestedPlaces = [];
  final PlaceCardUtils _placeCardUtils = PlaceCardUtils();
  final BuildDivider _buildDivider = BuildDivider();

  Position? _currentPosition;
  Placemark? _currentAddress;
  String _status = "No location yet yo";

  Weather? _weather;

  final DraggableScrollableController _scrollController = DraggableScrollableController();
  double _sheetPosition = 0.25;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.2926, 123.9022), // coords sa Cebu
    zoom: 14,
  );

  @override
  void initState(){
    super.initState();
    _initializeServices();
    _setupScrollListener();
    _loadSuggestedPlaces();
  }

  void _initializeServices() {
    // init weather service with API key
    final weatherApiKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];
    _weatherService = WeatherService(weatherApiKey!);

    _getLocationAndAddress();
    _fetchWeather();  
  }

  void _setupScrollListener() {
    // listen if naay position changes sa draggable sheet
    _scrollController.addListener(() {
      if (_scrollController.isAttached) {
        setState(() {
          _sheetPosition = _scrollController.size;
        });
      }
    });
  }
    Future<void> _loadSuggestedPlaces() async {
    setState(() => _isLoadingSuggested = true);
    final places = await _firebaseService.getSuggestedPlaces();

    setState(() {
      _suggestedPlaces = places;
      _isLoadingSuggested = false;
    });
  }

  // method for Weather
  Future<void> _fetchWeather() async {
    try {
      if (_currentPosition == null) {
        await _getLocationAndAddress();
      }

      if (_currentPosition != null) {
        final weather = await _weatherService.getWeather(_currentPosition!.longitude, _currentPosition!.latitude);

        if (mounted){
          setState(() {
            _weather = weather;
          });
        }
        
      }
    } catch (e) {
      logger.e('Failed to fetch weather: $e');
    }
  }

  //Function for geolocator
  Future<void> _getLocationAndAddress() async {
    setState(() => _status = "Fetching location...");

    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      if (mounted){
      setState(() => _status = "Location permission denied or service off.");
      }
      return;
    }

    final placemark = await _locationService.getAddressFromCoordinates(position);

    if (mounted){
        setState(() {
          _currentPosition = position;
          _currentAddress = placemark;
          _status = placemark != null ? "Location fetched successfully!" : "Failed to get address";
        });
    }

    await _fetchWeather();

    if (_mapManager.controller != null && mounted) {
      await _mapManager.animateToLocation(position);
      _mapManager.updateUserMarker(position, placemark);
      if (mounted){
        setState(() {
                
        }); 
      }
    
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapManager.setController(controller);

    if (_currentPosition != null) {
      _mapManager.animateToLocation(_currentPosition!);
      _mapManager.updateUserMarker(_currentPosition!, _currentAddress);
      setState(() {
        
      });
    }
  }

  void _centerMapOnUserLocation() {
    logger.i('Centering map on location of user...');
    _mapManager.animateToLocation(_currentPosition!);
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

  void _showWeatherModal() {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);
    return Scaffold(
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      body: Stack(
        children: [
          // Gogol maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _mapManager.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            // liteModeEnabled: true, // once naa najuy gogol maps, ill try erasing this
          ),

          // da buttons
          Positioned(
            right: 16,
            bottom: _calculateButtonPosition(),
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // centers the marker, i saw it somewhere sa YT
                    _centerMapOnUserLocation();
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(
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
                    Navigator.pushNamed(context, '/directionspage');
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(
                    Icons.directions,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          // draggable bottom sheet
          _buildBottomSheet(),
        ],
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

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      controller: _scrollController,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(50, 0, 0, 0),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              _buildStickyHeader(),
              _buildScrollableContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStickyHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: StickyHeaderDelegate(
        minHeight: 100,
        maxHeight: 100,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jeep Jam',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    _buildWeatherWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return GestureDetector(
      onTap: _showWeatherModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(48, 192, 191, 191),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _weather != null
                ? Lottie.asset(
                    WeatherUtils.getWeatherIcon(_weather?.mainCondition),
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  )
                : const Icon(Icons.cloud, size: 30),
            const SizedBox(width: 8),

            Text(
              '${_weather?.temperature.round() ?? '--'}℃',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Center(
            child: Text(
              'Your Location',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 13),
          
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
                      : 'Location off or permission denied',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

        // popular places / suggested places section)
        const Text(
          "Suggested Places",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _isLoadingSuggested
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          : _suggestedPlaces.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No suggested places available',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          : Column(
              children: _suggestedPlaces.map((place) {
                if (place['isDivider'] == true) {
                  return _buildDivider.buildDivider(place['location']);
                }
                return _placeCardUtils.buildPlaceCard(place);
              }).toList(),
            ),
          
          //how to read jeep
            GestureDetector(
                onTap: () => showCenterModalHowToRead(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue,
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  ),
                    child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.read_more, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'How to read Jeepney Codes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ],
                    )
                  ),
                ),

            const SizedBox(height: 16),
                //learn more about jeep jam
                 //how to read jeep
            GestureDetector(
                onTap: () => showCenterModalHowToLearn(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue,
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  ),
                    child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.read_more, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Learn More About Jeep Jam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ],
                    )
                  ),
                ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


}



