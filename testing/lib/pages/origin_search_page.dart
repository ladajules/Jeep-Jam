import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../services/places_service.dart';
import '../services/location.dart';
import '../pages/choose_on_map_page.dart';

class OriginSearchPage extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final String? initialOrigin;

  const OriginSearchPage({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.initialOrigin,
  });

  @override
  State<OriginSearchPage> createState() => _OriginSearchPageState();
}

class _OriginSearchPageState extends State<OriginSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  final LocationService _locationService = LocationService();
  late String _sessionToken;

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = const Uuid().v4();

    if (widget.initialOrigin != null && widget.initialOrigin!.isNotEmpty) {
      _searchController.text = widget.initialOrigin!;
      _fetchPredictions(widget.initialOrigin!);
    }

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialOrigin != null && widget.initialOrigin!.isNotEmpty) {
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      }
    });
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _fetchPredictions(_searchController.text);
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _fetchPredictions(String input) async {
    setState(() {
      _isLoading = true;
    });

    final predictions = await _placesService.getAutocompletePredictions(
      input,
      sessionToken: _sessionToken,
    );

    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    logger.i('Selected: ${prediction.description}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final placeDetails = await _placesService.getPlaceDetails(prediction.placeId);
    
    if (mounted) Navigator.pop(context);

    if (placeDetails != null) {
      _sessionToken = const Uuid().v4();
      
      if (mounted) {
        Navigator.pop(context, {
          'placeId': placeDetails.placeId,
          'name': placeDetails.name,
          'address': placeDetails.formattedAddress,
          'fullText': placeDetails.formattedAddress,
          'latitude': placeDetails.latitude,
          'longitude': placeDetails.longitude,
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get place details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _yourLocation() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        if (mounted) Navigator.pop(context); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your location. Please enable location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final placemark = await _locationService.getAddressFromCoordinates(position);
      
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (placemark != null) {
        final street = placemark.street ?? '';
        final locality = placemark.locality ?? '';
        final subLocality = placemark.subLocality ?? '';
        final administrativeArea = placemark.administrativeArea ?? '';
        final name = placemark.name ?? '';
        
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
        if (name.isNotEmpty) {
          if (fullAddress.isNotEmpty) fullAddress += ', ';
          fullAddress += name;
        }

        if (fullAddress.isEmpty) {
          fullAddress = 'Somewhere';
        }

        logger.i('User location: $fullAddress');

        if (mounted) {
          Navigator.pop(context, {
            'placeId': 'user_current_location',
            'name': name,
            'address': fullAddress,
            'fullText': fullAddress,
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
        }
      } else {
        if (mounted) {
          Navigator.pop(context, {
            'placeId': 'user_current_location',
            'name': 'Your Location',
            'address': 'Current location',
            'fullText': 'Your current location',
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
        }
      }
    } catch (e) {
      logger.e('Error getting user location: $e');
      
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your current location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: 'Choose start location',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty) 
            IconButton(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.clear, color: Colors.grey),
            ),
        ],
      ),

      body: Column(
        children: [
          GestureDetector(
            onTap: _yourLocation, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.blue.withValues(alpha: 0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Your Location',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.only(left: 55),
            child: const Divider(height: 1, color: Colors.grey),
          ),

          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChooseOnMapPage(mode: "origin")),
              );

              if (result != null && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context, result);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: const Color.fromARGB(255, 19, 18, 18),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Choose on map',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ),
          ),
          const Divider(height: 25, color: Colors.grey),

          Expanded(
            child: _buildResultsList(),
          ),

        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for a start location',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_predictions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
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
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildPredictionItem(prediction);
      },
    );
  }

  Widget _buildPredictionItem(PlacePrediction prediction) {
    return InkWell(
      onTap: () => _selectPrediction(prediction),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.location_on_outlined,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (prediction.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      prediction.secondaryText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}