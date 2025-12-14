import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

import '../controllers/map_manager.dart';
import '../services/location.dart';

class ChooseOnMapPage extends StatefulWidget {
  final String mode;

  const ChooseOnMapPage({
    super.key,
    required this.mode,
  });

  @override
  State<ChooseOnMapPage> createState() => _ChooseOnMapPageState();
}

class _ChooseOnMapPageState extends State<ChooseOnMapPage> {
  final MapManager _mapManager = MapManager();
  final LocationService _locationService = LocationService();
  final logger = Logger();

  Position? _currentPosition;

  LatLng? _centerLocation;
  String _centerAddress = 'Loading address...';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _currentPosition = position;
        _centerLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapManager.controller != null) {
        _mapManager.animateToLocation(position);
      }

      _updateCenterAddress();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapManager.setController(controller);

    if (_currentPosition != null) {
      _mapManager.animateToLocation(_currentPosition!);
    }
  }

  Future<void> _updateCenterAddress() async {
    if (_centerLocation == null) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _centerLocation!.latitude,
        _centerLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final street = placemark.street ?? '';
        final locality = placemark.locality ?? '';
        final subLocality = placemark.subLocality ?? '';
        final administrativeArea = placemark.administrativeArea ?? '';
        
        String fullAddress = '';
        if (street.isNotEmpty) fullAddress += street;
        if (subLocality.isNotEmpty) {
          if (fullAddress.isNotEmpty) fullAddress += ', ';
          fullAddress += subLocality;
        }
        if (locality.isNotEmpty) {
          if (fullAddress.isNotEmpty) fullAddress += ', ';
          fullAddress += locality;
        }
        if (administrativeArea.isNotEmpty) {
          if (fullAddress.isNotEmpty) fullAddress += ', ';
          fullAddress += administrativeArea;
        }

        if (fullAddress.isEmpty) {
          fullAddress = 'Unknown location';
        }

        setState(() {
          _centerAddress = fullAddress;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      //logger.e('Error getting address: $e'); // uncomment only when debugging
      setState(() {
        _centerAddress = 'Unable to get address';
        _isLoadingAddress = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _centerLocation = position.target;
    });
  }

  void _onCameraIdle() {
    _updateCenterAddress();
  }

  void _selectLocation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    Navigator.pop(context);

    Navigator.pop(context, {
      'placeId': 'map_selected_location',
      'name': _centerAddress.split(',').first,
      'address': _centerAddress,
      'fullText': _centerAddress,
      'latitude': _centerLocation!.latitude,
      'longitude': _centerLocation!.longitude,
    });
  }

  CameraPosition get _initialPosition => _currentPosition != null
    ? CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16,
      )
    : const CameraPosition(
        target: LatLng(10.2926, 123.9022), // Default coords sa Cebu
        zoom: 14,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            children: [
              Text(
                widget.mode == "origin" ? "Choose start location" : "Choose destination",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
                ),
              ),
              Text(
                'Pan and zoom to adjust',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          // gogol
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _mapManager.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          Center(
            child: Icon(
              Icons.location_on_sharp,
              size: 50,
              color: Colors.red,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          Positioned(
            top: 16,
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
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Text(
                            'Loading address...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          )
                        : Text(
                            _centerAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // floating buttons
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.40,
            child: Column(
              children: [
                // ok button
                // FloatingActionButton(
                //   onPressed: () {
                //     // selects place as destination/origin
                //   },
                //   backgroundColor: Colors.white,
                //   elevation: 4,
                //   child: const Icon(
                //     Icons.check,
                //     color: Colors.blue,
                //     size: 30,
                //   ),
                // ),
                // SizedBox(height: 15),

                FloatingActionButton(
                  onPressed: () {
                    // centers the marker, i saw it somewhere sa YT
                    _mapManager.animateToLocation(_currentPosition!);
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          // choose this button
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * 0.75,
                child: ElevatedButton(
                  onPressed: _selectLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.mode == 'origin' ? "Choose This Start Location" : "Choose This Destination",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}