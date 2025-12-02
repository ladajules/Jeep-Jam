import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:testing/pages/destination_search_page.dart';
import 'package:testing/pages/origin_search_page.dart';
import 'package:testing/services/firebase_service.dart';
import 'package:testing/services/location.dart';
import '../controllers/navigation_manager.dart';
import '../widgets/bottom_nav_bar.dart';

class SavedRoutesPage extends StatefulWidget{
  final String? route;
  final VoidCallback? onBack;

  const SavedRoutesPage({super.key, this.route, this.onBack});

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesState();
}

class _SavedRoutesState extends State<SavedRoutesPage>{
  int currentIndex = 2;
  final logger = Logger();
  final NavigationManager nav = NavigationManager();


    final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();

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

  List<Map<String, dynamic>> _savedRoutes = [];

  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    _getLocationAndAddress();
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
      
      //logger.i('Origin updated: ${result['fullText']}');
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
      
      //logger.i('Destination updated: ${result['fullText']}');
    }
  }

  

  void _selectSavedRoute(Map<String, dynamic> route) {
    setState(() {
      _originDetails = route['originDetails'];
      _destinationDetails = route['destinationDetails'];
      _originController.text = route['origin'];
      _destinationController.text = route['destination'];
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('${route['routeName']} loaded'),
    //     duration: const Duration(seconds: 1),
    //   ),
    // );
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

    try {
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
                  color: Colors.black,
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Color(0xff6e2d1b)),
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
                          'Please fill in both fields first',
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
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        routeNameController.dispose();
      });
    }
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
      backgroundColor: Color(0xfffef1d8),
      appBar: AppBar(
        backgroundColor:Color(0xfffef1d8),
        elevation: 0,
        title: const Text(
          'Saved Routes',
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
                        color: Color(0xfffef1d8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black!),
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
                                color: Color(0xfffef1d8),
                                size: 8,
                              ),
                            ),
                            SizedBox(width: 12),
                                
                            Expanded(
                              child: Text(
                                _originController.text.isEmpty ? 'To where?' : _originController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _originController.text.isEmpty ? Colors.black : Colors.black,
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
                        color: Color(0xfffef1d8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
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
                                color: Color(0xfffef1d8),
                                size: 8,
                              ),
                            ),
                            SizedBox(width: 12),
                                
                            Expanded(
                              child: Text(
                                _destinationController.text.isEmpty ? 'To where?' : _destinationController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _destinationController.text.isEmpty ? Colors.black: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                
                ],
              ),

              // scrollabe list view 
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xfffef1d8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // header with the Recent, Suggested, Saved
                      
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
    )
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 2:
      return _buildSavedList();

      default:
      return _buildSavedList();
    }
  }


  Widget _buildSavedList() {
    if (_isLoadingSaved) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedRoutes.isEmpty) {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              _showAddRouteDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xfffef1d8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xff6e2d1b),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Add new',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xff6e2d1b),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _showAddRouteDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xfffef1d8),
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
                    color: Color(0xff6e2d1b),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Add new',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xff6e2d1b),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
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
                      color: Color(0xfffef1d8),
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
                            color: Color(0xff6e2d1b),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bookmark,
                            color: Color(0xff6e2d1b),
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
                                    color: Color(0xff6e2d1b),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    route['jeepneyCode'].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xff6e2d1b),
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

  
  


     

