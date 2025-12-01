import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:testing/services/firebase_service.dart';
import 'package:testing/services/location.dart';
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

  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  final logger = Logger();

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // ignore: unused_field
  Position? _currentPosition;
  // ignore: unused_field
  Placemark? _currentAddress;
  // ignore: unused_field
  bool _hasLocationPermission = false;
  // ignore: unused_field
  bool _isLoadingLocation = false;

  int _selectedTab = 0; // for the tabs (Recent, Suggested, Saved)

  // ignore: unused_field
  Map<String, dynamic>? _destinationDetails;
  // ignore: unused_field
  Map<String, dynamic>? _originDetails;

  List<Map<String, dynamic>> _recentSearches = [];

  bool _isLoadingRecent = false;
  @override
  void initState() {
    super.initState();
    _getLocationAndAddress();
    _loadRecentSearches();
  }

  Future<void> _getLocationAndAddress() async {
    setState(() => _isLoadingLocation = true);
    final position = await _locationService.getCurrentLocation();

    if (position != null) {
      final placemark = await _locationService.getAddressFromCoordinates(position);
      
      setState(() {
        _currentPosition = position;
        _currentAddress = placemark;
        _hasLocationPermission = true;
        _isLoadingLocation = false;

        if (placemark != null) {
          _originController.text = '${placemark.street}, ${placemark.locality}';

          _originDetails = {
            'placeId': 'current_location',
            'name': '${placemark.street}, ${placemark.locality}',
            'address': '${placemark.street}, ${placemark.locality}',
            'fullText': '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}',
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        } else {
          _originController.text = 'From where?';
        }
      });
    } else {
      setState(() {
        _hasLocationPermission = false;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    setState(() => _isLoadingRecent = true);
    final searches = await _firebaseService.getRecentSearches();
    setState(() {
      _recentSearches = searches;
      _isLoadingRecent = false;
    });
  }



  void _selectRecentSearch(Map<String, dynamic> search) {
    setState(() {
      _originDetails = search['originDetails'];
      _destinationDetails = search['destinationDetails'];
      _originController.text = search['origin'];
      _destinationController.text = search['destination'];
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Recent search loaded'),
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }


  

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        
        title: const Text(
          'Recent Searches',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // input boxes and the submit button area
              
              const SizedBox(height: 15),

              // scrollabe list view 
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // header with the Recent, Suggested, Saved
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildTab('Recent', 0),
                          ],
                        ),
                      ),
                      
                      // scrollable list
                      Expanded(
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
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

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14, 
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
      return _buildRecentList();

      default:
      return _buildRecentList();
    }
  }

  Widget _buildRecentList() {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final search = _recentSearches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _selectRecentSearch(search),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          search['origin'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                search['destination'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  

 
}