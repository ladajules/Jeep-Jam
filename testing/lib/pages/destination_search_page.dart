import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../services/places_service.dart';

class DestinationSearchPage extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final String? initialDestination;

  const DestinationSearchPage({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.initialDestination,
  });

  @override
  State<DestinationSearchPage> createState() => _DestinationSearchPageState();
}

class _DestinationSearchPageState extends State<DestinationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  late String _sessionToken;

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = const Uuid().v4();

    if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
      _searchController.text = widget.initialDestination!;
      _fetchPredictions(widget.initialDestination!);
    }

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
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

  void _chooseOnMap() { // not done, should show map zzzzzzzz
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'rest sako, i do dis later',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.black,
      ),
    );
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
            hintText: 'Choose destination',
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

          InkWell(
            onTap: _chooseOnMap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[700],
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
          const Divider(height: 1, color: Colors.grey),

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
              'Search for a destination',
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