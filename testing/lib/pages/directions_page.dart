import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import 'package:testing/pages/destination_search_page.dart';
import 'package:testing/pages/origin_search_page.dart';
import 'package:testing/pages/directions_result_page.dart';

import '../services/location.dart';
import '../services/firebase_service.dart';

class DirectionsPage extends StatefulWidget {
  const DirectionsPage({super.key});

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
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
  List<Map<String, dynamic>> _suggestedPlaces = [];
  List<Map<String, dynamic>> _savedRoutes = [];

  bool _isLoadingRecent = false;
  bool _isLoadingSuggested = false;
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    _getLocationAndAddress();
    _loadRecentSearches();
    _loadSuggestedPlaces();
    _loadSavedRoutes();
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

  Future<void> _loadSuggestedPlaces() async {
    setState(() => _isLoadingSuggested = true);
    final places = await _firebaseService.getSuggestedPlaces();

    setState(() {
      _suggestedPlaces = places;
      _isLoadingSuggested = false;
    });
  }

  Future<void> _loadSavedRoutes() async {
    setState(() => _isLoadingSaved = true);
    final routes = await _firebaseService.getSavedRoutes();
    setState(() {
      _savedRoutes = routes;
      _isLoadingSaved = false;
    });
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
          'placeId': result['name'] ?? result['name'],
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
          'placeId': result['name'] ?? result['name'],
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

  Future<void> _handleSubmit() async {
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
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_originDetails == null || _destinationDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select valid locations from the search',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_originDetails!['latitude'] == null || 
        _originDetails!['longitude'] == null ||
        _destinationDetails!['latitude'] == null || 
        _destinationDetails!['longitude'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid location coordinates. Please try again.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    logger.i('Origin: ${_originController.text}');
    logger.i('Destination: ${_destinationController.text}');
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsResultPage(
          originDetails: _originDetails!,
          destinationDetails: _destinationDetails!,
        ),
      ),
    );
  }

  void _selectRecentSearch(Map<String, dynamic> search) {
    setState(() {
      _originDetails = search['originDetails'];
      _destinationDetails = search['destinationDetails'];
      _originController.text = search['origin'];
      _destinationController.text = search['destination'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recent search loaded'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _selectSuggestedPlace(Map<String, dynamic> place) async {
    final location = await _locationService.getCoordinatesFromAddress(place['location']);

    if (location != null) {
      setState(() {
        _destinationDetails = {
          'placeId': place['id'],
          'name': place['location'],
          'address': place['location'],
          'fullText': place['location'],
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
        _destinationController.text = place['location'];
      });
      
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('${place['location']} set as destination'),
      //     duration: const Duration(seconds: 1),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    }
  }

  void _selectSavedRoute(Map<String, dynamic> route) {
    setState(() {
      _originDetails = route['originDetails'];
      _destinationDetails = route['destinationDetails'];
      _originController.text = route['origin'];
      _destinationController.text = route['destination'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${route['routeName']} loaded'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteSavedRoute(String routeId, String routeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Delete "$routeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.deleteSavedRoute(routeId);
      _loadSavedRoutes();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddRouteDialog() async {
  final TextEditingController routeNameController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Save Current Route'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Give this route a name:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: routeNameController,
            decoration: InputDecoration(
              hintText: 'e.g., Home to Work',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          if (_originController.text.isNotEmpty && _destinationController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _originController.text,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _destinationController.text,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please set origin and destination first',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (routeNameController.text.trim().isEmpty) {
              Navigator.pop(context, false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a route name'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            
            if (_originDetails == null || _destinationDetails == null) {
              Navigator.pop(context, false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please set origin and destination first'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            
            Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (result == true && routeNameController.text.trim().isNotEmpty) {
    await _firebaseService.saveRoute(
      routeName: routeNameController.text.trim(),
      origin: _originController.text,
      destination: _destinationController.text,
      originDetails: _originDetails!,
      destinationDetails: _destinationDetails!,
    );

    await _loadSavedRoutes();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${routeNameController.text.trim()}" saved successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  routeNameController.dispose();
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

      case 1:
      return _buildSuggestedList();

      case 2:
      return _buildSavedList();

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
                  
                  const Icon(
                    Icons.arrow_forward,
                    size: 22,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedList() {
    if (_isLoadingSuggested) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: _suggestedPlaces.length,
      itemBuilder: (context, index) {
        final place = _suggestedPlaces[index];
        final isLandmark = place['isLandmark'] == true;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => _selectSuggestedPlace(place),
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
                      color: isLandmark ? Colors.amber[100] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLandmark ? Icons.location_city : Icons.trending_up,
                      color: isLandmark ? Colors.amber[700] : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['location'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        if (!isLandmark) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${place['count']} searches',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const Icon(
                    Icons.arrow_forward,
                    size: 22,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedList() {
    if (_isLoadingSaved) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedRoutes.isEmpty) {
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // navigator push to redirect to saved routes page
                  _showAddRouteDialog();
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
              const SizedBox(height: 50),
              Column(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved routes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // navigator push to redirect to saved routes page
            _showAddRouteDialog();
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
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: _savedRoutes.length,
            itemBuilder: (context, index) {
              final route = _savedRoutes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => _selectSavedRoute(route),
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
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bookmark,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route['routeName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${route['origin']} → ${route['destination']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (route['jeepneyCode'] != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    route['jeepneyCode'].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 22,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteSavedRoute(route['id'], route['routeName']),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

  }

}