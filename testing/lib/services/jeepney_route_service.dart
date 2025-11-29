import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sin, sqrt, asin, pi;
import '../services/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JeepneyRouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final logger = Logger();

  final Map<String, Location?> _stopLocationCache = {};
  final String _googleApiKey = dotenv.env['GOOGLE_CLOUD_API_KEY']!;

  Future<List<JeepneyRouteMatch>> findMatchingRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      logger.i('Finding routes from ($originLat, $originLng) to ($destLat, $destLng)');

      final snapshot = await _firestore.collection('jeepney_routes').get();
      
      List<JeepneyRouteMatch> matchingRoutes = [];

      for (var doc in snapshot.docs) {
        String routeCode = doc.id; 
        List<dynamic> stopsData = doc.data()['route'] ?? [];
        List<String> stops = stopsData.cast<String>(); 

        logger.d('Checking route $routeCode with ${stops.length} stops');

        JeepneyRouteMatch? match = await _checkIfJeepneyCanServeTrip(
          routeCode: routeCode,
          jeepneyStops: stops,
          userOriginLat: originLat,
          userOriginLng: originLng,
          userDestLat: destLat,
          userDestLng: destLng,
        );

        if (match != null) {
          matchingRoutes.add(match);
          logger.i('✓ Route $routeCode can serve this trip');
        }
      }

      matchingRoutes.sort((a, b) => a.totalETA.compareTo(b.totalETA));

      logger.i('Found ${matchingRoutes.length} matching routes');

      return matchingRoutes;
      
    } catch (e) {
      logger.e('Error finding routes: $e');
      return [];
    }
  }

  Future<JeepneyRouteMatch?> _checkIfJeepneyCanServeTrip({
    required String routeCode,
    required List<String> jeepneyStops,
    required double userOriginLat,
    required double userOriginLng,
    required double userDestLat,
    required double userDestLng,
  }) async {
    const double maxWalkDistance = 0.3; 

    StopMatch? boardingStop; 
    StopMatch? alightingStop;

    for (int i = 0; i < jeepneyStops.length; i++) {
      String stopName = jeepneyStops[i];
      
      Location? stopLocation = await _geocodeStop(stopName);
      if (stopLocation == null) {
        logger.w('Could not geocode stop: $stopName');
        continue;
      }

      double stopLat = stopLocation.latitude;
      double stopLng = stopLocation.longitude;

      if (boardingStop == null) {
        double distanceToOrigin = _calculateDistance(
          userOriginLat,
          userOriginLng,
          stopLat,
          stopLng,
        );

        if (distanceToOrigin <= maxWalkDistance) {
          boardingStop = StopMatch(
            index: i,
            name: stopName,
            latitude: stopLat,
            longitude: stopLng,
            walkDistance: distanceToOrigin,
          );
          logger.d('Found boarding stop: $stopName (${distanceToOrigin.toStringAsFixed(2)}km from origin)');
        }
      }

      if (boardingStop != null && i > boardingStop.index) {
        double distanceToDest = _calculateDistance(
          userDestLat,
          userDestLng,
          stopLat,
          stopLng,
        );

        if (distanceToDest <= maxWalkDistance) {
          alightingStop = StopMatch(
            index: i,
            name: stopName,
            latitude: stopLat,
            longitude: stopLng,
            walkDistance: distanceToDest,
          );
          logger.d('Found alighting stop: $stopName (${distanceToDest.toStringAsFixed(2)}km from destination)');
          break; 
        }
      }
    }

    if (boardingStop != null && alightingStop != null) {
      return await _buildRouteMatch(
        routeCode: routeCode,
        jeepneyStops: jeepneyStops,
        boardingStop: boardingStop,
        alightingStop: alightingStop,
        userOriginLat: userOriginLat,
        userOriginLng: userOriginLng,
        userDestLat: userDestLat,
        userDestLng: userDestLng,
      );
    }

    return null;
  }

  Future<JeepneyRouteMatch?> _buildRouteMatch({
    required String routeCode,
    required List<String> jeepneyStops,
    required StopMatch boardingStop,
    required StopMatch alightingStop,
    required double userOriginLat,
    required double userOriginLng,
    required double userDestLat,
    required double userDestLng,
  }) async {
    List<LatLng> routePolyline = await _getSimplifiedRoutePath(
      originLat: boardingStop.latitude,
      originLng: boardingStop.longitude,
      destLat: alightingStop.latitude,
      destLng: alightingStop.longitude,
    );

    double rideDistance = await _getRouteDistance(
      originLat: boardingStop.latitude,
      originLng: boardingStop.longitude,
      destLat: alightingStop.latitude,
      destLng: alightingStop.longitude,
    );

    double fare = _calculateFare(rideDistance);

    int walkToStopTime = _calculateWalkTime(boardingStop.walkDistance);
    int rideTime = _calculateRideTime(rideDistance);
    int walkFromStopTime = _calculateWalkTime(alightingStop.walkDistance);
    int totalETA = walkToStopTime + rideTime + walkFromStopTime;

    return JeepneyRouteMatch(
      code: routeCode,
      originStop: boardingStop,
      destStop: alightingStop,
      allStops: jeepneyStops,
      routePoints: routePolyline,
      distance: rideDistance,
      fare: fare,
      walkToStopTime: walkToStopTime,
      rideTime: rideTime,
      walkFromStopTime: walkFromStopTime,
      totalETA: totalETA,
      needsWalkToOrigin: boardingStop.walkDistance > 0.05, 
      needsWalkFromDest: alightingStop.walkDistance > 0.05,
    );
  }

  Future<List<LatLng>> _getSimplifiedRoutePath({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
        },
        body: json.encode({
          'origin': {
            'location': {
              'latLng': {'latitude': originLat, 'longitude': originLng}
            }
          },
          'destination': {
            'location': {
              'latLng': {'latitude': destLat, 'longitude': destLng}
            }
          },
          'travelMode': 'DRIVE',
          'polylineQuality': 'OVERVIEW', 
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPolyline = data['routes'][0]['polyline']['encodedPolyline'];
          return _decodePolyline(encodedPolyline);
        }
      } else {
        logger.e('Routes API error: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error getting route path: $e');
    }
    
    return [
      LatLng(originLat, originLng),
      LatLng(destLat, destLng),
    ];
  }

  Future<double> _getRouteDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'routes.distanceMeters',
        },
        body: json.encode({
          'origin': {
            'location': {
              'latLng': {'latitude': originLat, 'longitude': originLng}
            }
          },
          'destination': {
            'location': {
              'latLng': {'latitude': destLat, 'longitude': destLng}
            }
          },
          'travelMode': 'DRIVE',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final distanceMeters = data['routes'][0]['distanceMeters'];
          return distanceMeters / 1000.0;
        }
      }
    } catch (e) {
      logger.e('Error getting route distance: $e');
    }
    
    return _calculateDistance(originLat, originLng, destLat, destLng);
  }

  Future<Location?> _geocodeStop(String stopName) async {
    if (_stopLocationCache.containsKey(stopName)) {
      return _stopLocationCache[stopName];
    }

    try {
      Location? location = await _locationService.getCoordinatesFromAddress(
        '$stopName, Cebu City, Philippines',
      );

      if (location != null) {
        _stopLocationCache[stopName] = location;
        logger.d('Geocoded: $stopName -> (${location.latitude}, ${location.longitude})');
        return location;
      }
    } catch (e) {
      logger.w('Failed to geocode: $stopName - $e');
    }

    _stopLocationCache[stopName] = null;
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  double _calculateFare(double distanceKm) {
    const double baseFare = 13.0; 
    const double perKmRate = 2.25; 

    if (distanceKm <= 5) {
      return baseFare;
    } else {
      return baseFare + ((distanceKm - 5) * perKmRate);
    }
  }

  int _calculateWalkTime(double distanceKm) {
    const double walkingSpeed = 5.0; // km/h
    return ((distanceKm / walkingSpeed) * 60).round(); 
  }

  int _calculateRideTime(double distanceKm) {
    const double averageSpeed = 20.0; // km/h
    return ((distanceKm / averageSpeed) * 60).round(); 
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void clearCache() {
    _stopLocationCache.clear();
    logger.i('Geocoding cache cleared');
  }
}

class JeepneyRouteMatch {
  final String code;
  final StopMatch originStop; 
  final StopMatch destStop; 
  final List<String> allStops; 
  final List<LatLng> routePoints; 
  final double distance; 
  final double fare; 
  final int walkToStopTime; 
  final int rideTime; 
  final int walkFromStopTime; 
  final int totalETA;
  final bool needsWalkToOrigin;
  final bool needsWalkFromDest; 

  JeepneyRouteMatch({
    required this.code,
    required this.originStop,
    required this.destStop,
    required this.allStops,
    required this.routePoints,
    required this.distance,
    required this.fare,
    required this.walkToStopTime,
    required this.rideTime,
    required this.walkFromStopTime,
    required this.totalETA,
    required this.needsWalkToOrigin,
    required this.needsWalkFromDest,
  });

  String getRouteSummary() {
    return '${code.toUpperCase()}: ${originStop.name} → ${destStop.name}';
  }

  String getTripDescription() {
    List<String> steps = [];
    
    if (needsWalkToOrigin) {
      steps.add('Walk ${(originStop.walkDistance * 1000).round()}m to ${originStop.name}');
    }
    
    steps.add('Ride ${code.toUpperCase()} for ${distance.toStringAsFixed(1)}km');
    
    if (needsWalkFromDest) {
      steps.add('Walk ${(destStop.walkDistance * 1000).round()}m from ${destStop.name}');
    }
    
    return steps.join(' → ');
  }
}

class StopMatch {
  final int index; 
  final String name; 
  final double latitude;
  final double longitude;
  final double walkDistance; 

  StopMatch({
    required this.index,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.walkDistance,
  });

  bool get requiresWalking => walkDistance > 0.05; 
  int get walkingTimeMinutes => ((walkDistance / 5) * 60).round();
  int get walkingDistanceMeters => (walkDistance * 1000).round();
}