import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placePrediction']['placeId'],
      description: json['placePrediction']['text']['text'],
      mainText: json['placePrediction']['structuredFormat']['mainText']['text'],
      secondaryText: json['placePrediction']['structuredFormat']['secondaryText']?['text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    
    return PlaceDetails(
      placeId: json['id'],
      name: json['displayName']?['text'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      latitude: location['latitude'],
      longitude: location['longitude'],
    );
  }
}

class PlacesService {
  final logger = Logger();
  final String? apiKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];
  
  static const String _autocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static const String _placeDetailsUrl = 'https://places.googleapis.com/v1/places/';

  Future<List<PlacePrediction>> getAutocompletePredictions(
    String input, {
    String? sessionToken,
    double? latitude,
    double? longitude,
  }) async {
    if (input.isEmpty) return [];
    
    try {
      final url = Uri.parse(_autocompleteUrl);

      final body = {
        'input': input,
        'sessionToken': sessionToken ?? 'default_session',
        'includedRegionCodes': ['PH'],
        'locationRestriction': {
          'rectangle': {
            'low': {
              'latitude': 9.5,
              'longitude': 123.3,
            },
            'high': {
              'latitude': 11.3,
              'longitude': 124.1,
            }
          }
        }
      };

      if (latitude != null && longitude != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 50000.0,
          }
        };
      }

      //logger.i('Fetching predictions for: $input'); // only uncomment when debugging
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey ?? '',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['suggestions'] != null) {
          final predictions = (data['suggestions'] as List)
              .map((json) => PlacePrediction.fromJson(json))
              .toList();
          
          //logger.i('Found ${predictions.length} predictions'); // only uncomment when debugging
          return predictions;
        } else {
          //logger.w('No suggestions found'); // only uncomment when debugging
          return [];
        }
      } else {
        logger.e('HTTP error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Error getting predictions: $e');
      return [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse('$_placeDetailsUrl$placeId');

      //logger.i('Fetching details for place: $placeId'); // only uncomment when debugging
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey ?? '',
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlaceDetails.fromJson(data);
      } else {
        logger.e('HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting place details: $e');
      return null;
    }
  }
}