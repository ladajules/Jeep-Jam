import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sin, sqrt, asin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JeepneyRouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger();

  final String _googleApiKey = dotenv.env['GOOGLE_CLOUD_API_KEY']!;

  Future<List<JeepneyRouteMatch>> findMatchingRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originName, 
    String? destName, 
  }) async {
    try {
      logger.i('Finding routes from ($originLat, $originLng) to ($destLat, $destLng)');

      if (originName != null && destName != null) {
        final cachedResult = await _checkSearchCacheByName(
          originName, 
          destName, 
          originLat, 
          originLng, 
          destLat, 
          destLng
        );
        if (cachedResult != null && cachedResult.isNotEmpty) {
          logger.i('✓ Found ${cachedResult.length} cached routes');
          return cachedResult;
        }
      }

      logger.i('Cache miss, searching all routes...'); // for debugging, dont uncomment unless necessary

      final snapshot = await _firestore.collection('jeepney_routes').get();
      List<JeepneyRouteMatch> matchingRoutes = [];

      for (var doc in snapshot.docs) {
        String routeCode = doc.id; 
        Map<String, dynamic> data = doc.data();
        List<dynamic> routeData = data['route'] ?? [];
        List<String> stopNames = [];
        List<Map<String, dynamic>> stopCoordinates = [];

        for (var stop in routeData) {
          if (stop is Map<String, dynamic>) {
            stopNames.add(stop['name'] ?? 'Unknown Stop');
            stopCoordinates.add({
              'lat': stop['lat'],
              'lng': stop['lng'],
            });
          }
        }

        JeepneyRouteMatch? match = await _checkIfJeepneyCanServeTrip(
          routeCode: routeCode,
          stopNames: stopNames,
          stopCoordinates: stopCoordinates,
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

  Future<List<JeepneyRouteMatch>?> _checkSearchCacheByName(
    String origin,
    String dest,
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final cleanOrigin = origin.replaceAll(RegExp(r'[/#]'), '_');
      final cleanDest = dest.replaceAll(RegExp(r'[/#]'), '_');
      final docId = '$cleanOrigin - $cleanDest';

      logger.i('Checking cache for: $docId');

      final docSnapshot = await _firestore.collection('search_cache').doc(docId).get();

      if (docSnapshot.exists) {
        logger.i('Cache hit! Found cached route for $origin -> $dest');
        
        final data = docSnapshot.data()!;
        List<dynamic> cachedCodes = data['codes'] ?? [];
        
        if (cachedCodes.isEmpty) {
          logger.w('Cache exists but no codes found');
          return null;
        }

        logger.i('Found ${cachedCodes.length} cached codes: $cachedCodes');

        List<JeepneyRouteMatch> routes = [];

        for (String code in cachedCodes) {
          final routeDoc = await _firestore.collection('jeepney_routes').doc(code).get();

          final routeData = routeDoc.data()!;
          List<dynamic> routeArray = routeData['route'] ?? [];
          List<String> stopNames = [];
          List<Map<String, dynamic>> stopCoordinates = [];

          for (var stop in routeArray) {
            if (stop is Map<String, dynamic>) {
              stopNames.add(stop['name'] ?? 'Unknown Stop');
              stopCoordinates.add({
                'lat': stop['lat'],
                'lng': stop['lng'],
              });
            }
          }

          JeepneyRouteMatch? match = await _checkIfJeepneyCanServeTrip(
            routeCode: code,
            stopNames: stopNames,
            stopCoordinates: stopCoordinates,
            userOriginLat: originLat,
            userOriginLng: originLng,
            userDestLat: destLat,
            userDestLng: destLng,
          );

          if (match != null) {
            routes.add(match);
            logger.i('✓ Cached route $code matched');
          } else {
            logger.w('Cached route $code did not match current coordinates');
          }
        }

        if (routes.isNotEmpty) {
          routes.sort((a, b) => a.totalETA.compareTo(b.totalETA));
          return routes;
        } else {
          logger.w('No cached routes matched the trip requirements');
          return null;
        }
      } else {
        logger.i('Cache miss - document not found: $docId');
      }
    } catch (e) {
      logger.e('Error checking cache: $e');
    }

    return null;
  }

  // Future<List<JeepneyRouteMatch>?> _checkSearchCache(
  //   double originLat,
  //   double originLng,
  //   double destLat,
  //   double destLng,
  // ) async {
  //   try {
  //     final snapshot = await _firestore.collection('search_cache').get();

  //     for (var doc in snapshot.docs) {
  //       final data = doc.data();
        
  //       if (data['originLat'] != null && data['originLng'] != null &&
  //         data['destLat'] != null && data['destLng'] != null) {

  //         double cachedOriginLat = data['originLat'].toDouble();
  //         double cachedOriginLng = data['originLng'].toDouble();
  //         double cachedDestLat = data['destLat'].toDouble();
  //         double cachedDestLng = data['destLng'].toDouble();

  //         double originDistance = _calculateDistance(originLat, originLng, cachedOriginLat, cachedOriginLng);
  //         double destDistance = _calculateDistance(destLat, destLng, cachedDestLat, cachedDestLng);

  //         if (originDistance < 0.1 && destDistance < 0.1) {
  //           logger.i('Cache hit! Using cached routes');
            
  //           List<dynamic> cachedCodes = data['codes'] ?? [];
  //           List<JeepneyRouteMatch> routes = [];

  //           for (String code in cachedCodes) {
  //             final routeDoc = await _firestore.collection('jeepney_routes').doc(code).get();
              
  //             if (!routeDoc.exists) continue;

  //             final routeData = routeDoc.data()!;
  //             List<dynamic> stopsData = routeData['route'] ?? [];
  //             List<String> stopNames = stopsData.cast<String>();
  //             List<dynamic> coordinatesData = routeData['coordinates'] ?? [];

  //             if (coordinatesData.isEmpty) continue;

  //             JeepneyRouteMatch? match = await _checkIfJeepneyCanServeTrip(
  //               routeCode: code,
  //               stopNames: stopNames,
  //               stopCoordinates: coordinatesData,
  //               userOriginLat: originLat,
  //               userOriginLng: originLng,
  //               userDestLat: destLat,
  //               userDestLng: destLng,
  //             );

  //             if (match != null) {
  //               routes.add(match);
  //             }
  //           }

  //           routes.sort((a, b) => a.totalETA.compareTo(b.totalETA));
  //           return routes;
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     logger.e('Error checking cache: $e');
  //   }

  //   return null;
  // }

  Future<JeepneyRouteMatch?> _checkIfJeepneyCanServeTrip({
    required String routeCode,
    required List<String> stopNames,
    required List<dynamic> stopCoordinates,
    required double userOriginLat,
    required double userOriginLng,
    required double userDestLat,
    required double userDestLng,
  }) async {
    const double maxWalkDistance = 0.3;

    StopMatch? boardingStop;
    StopMatch? alightingStop;

    for (int i = 0; i < stopCoordinates.length; i++) {
      if (i >= stopNames.length) break;

      final coord = stopCoordinates[i];
      if (coord == null || coord['lat'] == null || coord['lng'] == null) {
        continue;
      }

      double stopLat = coord['lat'].toDouble();
      double stopLng = coord['lng'].toDouble();
      String stopName = stopNames[i];

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
          break;
        }
      }
    }

    if (boardingStop != null && alightingStop != null) {
      return await _buildRouteMatch(
        routeCode: routeCode,
        jeepneyStops: stopNames,
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
    List<LatLng> routePolyline = await _getRoutePath(
      originLat: boardingStop.latitude,
      originLng: boardingStop.longitude,
      destLat: alightingStop.latitude,
      destLng: alightingStop.longitude,
      travelMode: 'DRIVE',
    );

    List<LatLng> walkToOriginPoints = [];
    if (boardingStop.walkDistance > 0.05) {
      walkToOriginPoints = await _getRoutePath(
        originLat: userOriginLat,
        originLng: userOriginLng,
        destLat: boardingStop.latitude,
        destLng: boardingStop.longitude,
        travelMode: 'WALK', 
      );
    }

    List<LatLng> walkFromDestPoints = [];
    if (alightingStop.walkDistance > 0.05) {
      walkFromDestPoints = await _getRoutePath(
        originLat: alightingStop.latitude,
        originLng: alightingStop.longitude,
        destLat: userDestLat,
        destLng: userDestLng,
        travelMode: 'WALK', 
      );
    }

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
      walkToOriginPoints: walkToOriginPoints, 
      walkFromDestPoints: walkFromDestPoints,
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

  Future<List<LatLng>> _getRoutePath({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String travelMode = 'DRIVE',
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
          'travelMode': travelMode,
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
  
}

class JeepneyRouteMatch {
  final String code;
  final StopMatch originStop; 
  final StopMatch destStop; 
  final List<String> allStops; 
  final List<LatLng> routePoints; 
  final List<LatLng> walkToOriginPoints; 
  final List<LatLng> walkFromDestPoints;
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
    required this.walkToOriginPoints,
    required this.walkFromDestPoints,
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