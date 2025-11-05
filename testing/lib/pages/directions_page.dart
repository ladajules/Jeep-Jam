import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:testing/pages/destination_search_page.dart';
import 'package:testing/pages/origin_search_page.dart';
import '../services/location.dart';

class DirectionsPage extends StatefulWidget {
  const DirectionsPage({super.key});

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  final LocationService _locationService = LocationService();
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

  @override
  void initState() {
    super.initState();
    _getLocationAndAddress();
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

  Future<void> _openOriginSearch() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => OriginSearchPage(
      userLatitude: _currentPosition?.latitude,
      userLongitude: _currentPosition?.longitude,
      initialOrigin: _originController.text.isNotEmpty ? _originController.text : null,
    )));

    if (result != null && result is Map) {
      setState(() {
        _originDetails = {
          'placeId': result['name'],
          'name': result['name'],
          'address': result['address'],
          'fullText': result['fullText'],
          'latitude': result['latitude'],
          'longitude': result['longitude'],
        };
      });

      _originController.text = result['name'] ?? '';
      
      logger.i('Origin updated: ${result['fullText']}');
    }
  }

  Future<void> _openDestinationSearch() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DestinationSearchPage(
      userLatitude: _currentPosition?.latitude,
      userLongitude: _currentPosition?.longitude,
      initialDestination: _destinationController.text.isNotEmpty ? _destinationController.text : null,
    )));

    if (result != null && result is Map) {
      setState(() {
        _destinationDetails = {
          'placeId': result['name'],
          'name': result['name'],
          'address': result['address'],
          'fullText': result['fullText'],
          'latitude': result['latitude'],
          'longitude': result['longitude'],
        };
      });

      _destinationController.text = result['name'] ?? '';
      
      logger.i('Destination updated: ${result['fullText']}');
    }
  }

  void _handleSubmit() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in both location fields',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    logger.i('Origin: ${_originController.text}');
    logger.i('Destination: ${_destinationController.text}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for directions...'),
        backgroundColor: Colors.green,
      ),
    );
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Plan Your Route',
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
              Column( 
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 25),
                
                  GestureDetector(
                    onTap: _openOriginSearch,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                                    
                      // origin input 
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                                
                              child: Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                            SizedBox(width: 12),
                                
                            Expanded(
                              child: Text(
                                _originController.text.isEmpty ? 'To where?' : _originController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _originController.text.isEmpty ? Colors.grey[500] : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                                    
                    ),
                  ),
                  const SizedBox(height: 10),
                
                  GestureDetector(
                    onTap: _openDestinationSearch,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                                    
                      // destination input
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                                
                              child: Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                            SizedBox(width: 12),
                                
                            Expanded(
                              child: Text(
                                _destinationController.text.isEmpty ? 'To where?' : _destinationController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _destinationController.text.isEmpty ? Colors.grey[500] : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                            _buildTab('Suggested', 1),
                            _buildTab('Saved', 2),
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
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        logger.i('$title tab selected...');
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          // boxShadow: [
          //   if (isSelected) BoxShadow(
          //     color: Colors.blue.withValues(alpha: 0.3),
          //     spreadRadius: 1,
          //     blurRadius: 4,
          //     offset: const Offset(0, 2),
          //   )
          // ],
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

      case 1:
      return _buildSuggestedList();

      case 2:
      return _buildSavedList();

      default:
      return _buildRecentList();
    }
  }

  Widget _buildRecentList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      children: [
        // list to see
        ...List.generate(15, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            height: 80,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // clock icon
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
                  
                  // full full address
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Search ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sample location address',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      logger.i('Recent Search ${index + 1} pressed...');
                    },
                    child: Icon(
                      Icons.arrow_forward,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuggestedList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      children: [
        // list to see
        ...List.generate(15, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            height: 80,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // clock icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // full full address
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggested Place ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sample location address',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      logger.i('Suggested Place ${index + 1} pressed...');
                    },
                    child: Icon(
                      Icons.arrow_forward,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSavedList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      children: [
        GestureDetector(
          onTap: () {
            // navigator push to redirect to saved routes page
            logger.i('Add new button pressed in Saved tab...');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
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
                    Icons.add_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Add new',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),

        // list to see
        ...List.generate(15, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            height: 80,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // clock icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // full full address
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Route ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: Sample location address',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  GestureDetector(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
        
        const SizedBox(height: 20),
      ],
    );
  }

}