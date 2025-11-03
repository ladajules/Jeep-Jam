import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
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
  bool _hasLocationPermission = false;
  // ignore: unused_field
  bool _isLoadingLocation = false;

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
      });
    }
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
              SizedBox(height: 25),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),

                child: Column(
                  children: [

                    // origin input 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.my_location,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: _originController,
                              enabled: !_hasLocationPermission,
                              decoration: InputDecoration(
                                hintText: 'From where?',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),

                child: Column(
                  children: [

                    // destination input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.my_location_outlined,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                hintText: 'To where?',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}