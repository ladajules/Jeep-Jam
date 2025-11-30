import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
//import 'package:geocoding/geocoding.dart';
import '../services/jeepney_route_service.dart';
import '../services/firebase_service.dart';
import 'dart:ui' as ui;
//import '../controllers/map_manager.dart';

class DirectionsResultPage extends StatefulWidget {
  final Map<String, dynamic> originDetails;
  final Map<String, dynamic> destinationDetails;

  const DirectionsResultPage({
    super.key,
    required this.originDetails,
    required this.destinationDetails,
  });

  @override
  State<DirectionsResultPage> createState() => _DirectionsResultPageState();
}

class _DirectionsResultPageState extends State<DirectionsResultPage> {
  final logger = Logger();
  final JeepneyRouteService _routeService = JeepneyRouteService();
  final FirebaseService _firebaseService = FirebaseService();
  
  GoogleMapController? _mapController;
  //MapManager _mapManager = MapManager();
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  List<JeepneyRouteMatch> _availableRoutes = [];
  JeepneyRouteMatch? _selectedRoute;
  bool _isLoading = true;

  final DraggableScrollableController _scrollController = DraggableScrollableController();

  double _sheetPosition = 0.25;
  bool _isRouteSaved = false;
  String? _savedRouteId;

  @override
  void initState() {
    super.initState();
    _initializeDirections();
    _setupScrollListener();
    _checkIfRouteSaved();
  }

  Future<void> _checkIfRouteSaved() async {
    try {
      final savedRoutes = await _firebaseService.getSavedRoutes();
      
      final savedRoute = savedRoutes.firstWhere(
        (route) {
          logger.i('Comparing with saved route - Origin: ${route['origin']}, Dest: ${route['destination']}, ID: ${route['id']}');
          return route['origin'] == widget.originDetails['name'] &&
                route['destination'] == widget.destinationDetails['name'];
        },
        orElse: () => {},
      );
      
      setState(() {
        _isRouteSaved = savedRoute.isNotEmpty;
        _savedRouteId = savedRoute.isNotEmpty ? savedRoute['id'] : null;
      });
    } catch (e) {
      logger.e('Error checking if route is saved: $e');
    }
  }

  Future<void> cacheRecentSearch({
    required List<JeepneyRouteMatch> codes,
    required String origin,
    required String destination,
    required Map<String, dynamic> originDetails,
    required Map<String, dynamic> destinationDetails,
  }) async {
    try {
      await _firebaseService.saveRecentSearch(
        origin: origin,
        destination: destination,
        originDetails: originDetails,
        destinationDetails: destinationDetails,
        codes: codes,
      );

    } catch (e) {
      logger.e('Error caching recent search: $e');
    }
  }

  Future<void> _initializeDirections() async {
    setState(() => _isLoading = true);

    _addLocationMarkers();

    await _findAvailableRoutes();

    if (_availableRoutes.isNotEmpty) {
      _selectRoute(_availableRoutes.first);
    }

    await cacheRecentSearch(
      codes: _availableRoutes,
      origin: widget.originDetails['name'], 
      destination: widget.destinationDetails['name'],
      originDetails: widget.originDetails,
      destinationDetails: widget.destinationDetails,
    );

    setState(() => _isLoading = false);
  }

  Future<BitmapDescriptor> _bitmapFromIcon(IconData icon) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 40.0,
        color: Colors.blue,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );

    iconPainter.layout();
    iconPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(64, 64);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _addLocationMarkers() async {
    // origin marker
    final blueGpsIcon = await _bitmapFromIcon(Icons.circle);

    _markers.add(
      Marker(
        markerId: MarkerId('origin'),
        position: LatLng(
          widget.originDetails['latitude'],
          widget.originDetails['longitude'],
        ),
        icon: blueGpsIcon,
        infoWindow: InfoWindow(
          title: "You are here",
          snippet: widget.originDetails['name'],
        ),
      ),
    );

    // dest marker
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.destinationDetails['latitude'],
          widget.destinationDetails['longitude'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.destinationDetails['name'],
        ),
      ),
    );
  }

  Future<void> _findAvailableRoutes() async {
    try {
      List<JeepneyRouteMatch> routes = await _routeService.findMatchingRoutes(
        originLat: widget.originDetails['latitude'],
        originLng: widget.originDetails['longitude'],
        destLat: widget.destinationDetails['latitude'],
        destLng: widget.destinationDetails['longitude'],
        originName: widget.originDetails['name'],   
        destName: widget.destinationDetails['name'],
      );

      setState(() {
        _availableRoutes = routes;
      });

      logger.i('Found ${routes.length} available routes');
    } catch (e) {
      logger.e('Error finding routes: $e');
    }
  }

  void _selectRoute(JeepneyRouteMatch route) {
    setState(() {
      _selectedRoute = route;
      _updateMapForRoute(route);
    });
  }

  void _updateMapForRoute(JeepneyRouteMatch route) async {
    _polylines.clear();
    _markers.clear();

    final blueGpsIcon = await _bitmapFromIcon(Icons.circle);

    _markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: LatLng(
          widget.originDetails['latitude'],
          widget.originDetails['longitude'],
        ),
        icon: blueGpsIcon,
        infoWindow: InfoWindow(
          title: 'You are here',
          snippet: widget.originDetails['name'],
        ),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.destinationDetails['latitude'],
          widget.destinationDetails['longitude'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.destinationDetails['name'],
        ),
      ),
    );
    
    if (route.needsWalkToOrigin) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('walk_to_origin'),
        points: route.walkToOriginPoints.isNotEmpty 
            ? route.walkToOriginPoints 
            : [ 
                LatLng(
                  widget.originDetails['latitude'],
                  widget.originDetails['longitude'],
                ),
                LatLng(
                  route.originStop.latitude,
                  route.originStop.longitude,
                ),
              ],
        color: Colors.orange,
        width: 4,
        patterns: [
          PatternItem.dash(10),
          PatternItem.gap(5),
        ],
      ));
    }

    if (route.routePoints.isNotEmpty) {
      _polylines.add(Polyline(
        polylineId: PolylineId('jeepney_${route.code}'),
        points: route.routePoints,
        color: Colors.blue,
        width: 6,
      ));
    }

    if (route.needsWalkFromDest) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('walk_from_dest'),
        points: route.walkFromDestPoints.isNotEmpty
            ? route.walkFromDestPoints
            : [ 
                LatLng(
                  route.destStop.latitude,
                  route.destStop.longitude,
                ),
                LatLng(
                  widget.destinationDetails['latitude'],
                  widget.destinationDetails['longitude'],
                ),
              ],
        color: Colors.orange,
        width: 4,
        patterns: [
          PatternItem.dash(10),
          PatternItem.gap(5),
        ],
      ));
    }

    _fitRouteInView();
  }

  void _fitRouteInView() {
    if (_mapController == null || _selectedRoute == null) return;

    List<LatLng> allPoints = [];
    
    allPoints.add(LatLng(
      widget.originDetails['latitude'],
      widget.originDetails['longitude'],
    ));
    
    allPoints.add(LatLng(
      widget.destinationDetails['latitude'],
      widget.destinationDetails['longitude'],
    ));

    allPoints.addAll(_selectedRoute!.routePoints);

    if (allPoints.length < 2) return;

    double minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 170),
    );
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

  Future<void> _showAddRouteDialog(String origin, String dest) async {
    if (_isRouteSaved) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove saved route', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to remove this route?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
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
                            origin,
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
                            dest,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (result == true && _savedRouteId != null) {
        await _firebaseService.deleteSavedRoute(_savedRouteId!);
        
        setState(() {
          _isRouteSaved = false;
          _savedRouteId = null;
        });
      
      }
      return;
    }

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
            if (origin.isNotEmpty && dest.isNotEmpty) ...[
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
                            origin,
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
                            dest,
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
        origin: origin,
        destination: dest,
        originDetails: widget.originDetails,
        destinationDetails: widget.destinationDetails,
      );

      await _checkIfRouteSaved();
    }

    routeNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedRoute != null) {
                      _fitRouteInView();
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.originDetails['latitude'],
                      widget.originDetails['longitude'],
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
    
                // origin and dest container
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.originDetails['name'],
                                style: TextStyle(
                                  fontSize: 16
                                ),
                              ),
                            ),
                          ],
                        ),
                    
                        const SizedBox(height: 6),
                        const Divider(),
                        const SizedBox(height: 6),
                    
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.destinationDetails['name'],
                                style: TextStyle(
                                  fontSize: 16
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                      
                  ),
                ),
    
                // floating buttons
                Positioned(
                  right: 16,
                  bottom: _calculateButtonPosition(),
                  child: FloatingActionButton(
                    onPressed: () {
                      // centers the map to see the entire route
                      _fitRouteInView();
                    },
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(
                      Icons.near_me_outlined,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ),
                
                // Positioned(
                //   top: 16,
                //   right: 16,
                //   child: Padding(
                //     padding: const EdgeInsets.only(top: 70),
                //     child: Container(
                //       padding: const EdgeInsets.all(12),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(8),
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.grey.withOpacity(0.3),
                //             spreadRadius: 1,
                //             blurRadius: 4,
                //           ),
                //         ],
                //       ),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           _buildLegendItem(Colors.blue, 'Jeepney Route'),
                //           const SizedBox(height: 6),
                //           _buildLegendItem(Colors.orange, 'Walking'),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
    
                _buildBottomSheet(),
              ],
            ),
    );
  }

  // uncomment if they like
  // Widget _buildLegendItem(Color color, String label) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 20,
  //         height: 3,
  //         color: color,
  //       ),
  //       const SizedBox(width: 6),
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 12),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      controller: _scrollController,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(50, 0, 0, 0),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Public transport',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_availableRoutes.length} ${_availableRoutes.length == 1 ? "route" : "routes"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        // pop up dialog
                        _showAddRouteDialog(widget.originDetails['name'], widget.destinationDetails['name']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRouteSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
                          color: _isRouteSaved ? Colors.orangeAccent : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _availableRoutes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_very_dissatisfied,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cant find any jeepneys',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _availableRoutes.length,
                        itemBuilder: (context, index) {
                          return _buildRouteCard(_availableRoutes[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(JeepneyRouteMatch route) {
    bool isSelected = _selectedRoute?.code == route.code;

    return GestureDetector(
      onTap: () => _selectRoute(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            route.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${route.totalETA} min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.distance.toStringAsFixed(1)} km • ₱${route.fare.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ],
            ),

            if (isSelected) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              _buildTripStep(
                icon: Icons.directions_walk,
                color: Colors.orange,
                label: 'Walk to ${route.originStop.name}',
                duration: '${route.walkToStopTime} min',
                distance: '${(route.originStop.walkDistance * 1000).round()} m',
              ),
              
              const SizedBox(height: 8),
              
              _buildTripStep(
                icon: Icons.directions_bus,
                color: Colors.blue,
                label: 'Ride ${route.code.toUpperCase()}',
                duration: '${route.rideTime} min',
                distance: '${route.distance.toStringAsFixed(1)} km',
              ),
              
              if (route.needsWalkFromDest) ...[
                const SizedBox(height: 8),
                _buildTripStep(
                  icon: Icons.directions_walk,
                  color: Colors.orange,
                  label: 'Walk from ${route.destStop.name}',
                  duration: '${route.walkFromStopTime} min',
                  distance: '${(route.destStop.walkDistance * 1000).round()} m',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripStep({
    required IconData icon,
    required Color color,
    required String label,
    required String duration,
    required String distance,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$duration • $distance',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}