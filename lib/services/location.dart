import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'dart:math' show cos, sin, sqrt, asin, pi, atan;

class LocationService {
  final logger = Logger();

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await handlePermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<Placemark?> getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude, 
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }

    } catch (e) {
      logger.e('Error in getAddressFromCoordinates: $e');
    }

    return null;
  }

  Future <Location?> getCoordinatesFromAddress(String address) async {
    try {
      List <Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      logger.e('Error in getCoordinatesFromAddress: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    final placemark = await getAddressFromCoordinates(position);

    return {
      'position': position,
      'address': placemark,
    };

  }

  Future getCurrentCity () async{
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings
    );

    List <Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    String? city = placemarks[0].locality;

    return city ?? "";

  }

}

final LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high
);

extension LocationExtensions on Location {
  double distanceTo(Location other) {
    return LocationUtils.calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  double distanceToCoordinates(double lat, double lng) {
    return LocationUtils.calculateDistance(latitude, longitude, lat, lng);
  }

  bool isWithinDistance(Location other, double distanceKm) {
    return distanceTo(other) <= distanceKm;
  }

  bool isWalkableFrom(Location other) {
    return distanceTo(other) <= 0.3;
  }
}

extension PositionExtensions on Position {
  double distanceTo(Position other) {
    return LocationUtils.calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  double distanceToCoordinates(double lat, double lng) {
    return LocationUtils.calculateDistance(latitude, longitude, lat, lng);
  }

  Map<String, double> toCoordinates() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }


  bool isInCebuCity() {
    const double minLat = 10.25;
    const double maxLat = 10.40;
    const double minLng = 123.85;
    const double maxLng = 123.95;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }
}

class LocationUtils {
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // haversine formukla
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

  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistance(lat1, lon1, lat2, lon2) * 1000;
  }

  static bool isWalkingDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistanceMeters(lat1, lon1, lat2, lon2) <= 300;
  }

  static int estimateWalkingTime(double distanceKm) {
    const double walkingSpeedKmh = 5.0;
    return ((distanceKm / walkingSpeedKmh) * 60).round();
  }

  static int estimateJeepneyTime(double distanceKm) {
    const double jeepneySpeedKmh = 20.0;
    return ((distanceKm / jeepneySpeedKmh) * 60).round();
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? "hour" : "hours"}';
      } else {
        return '$hours ${hours == 1 ? "hr" : "hrs"} $remainingMinutes min';
      }
    }
  }

  static double calculateFare(double distanceKm) {
    const double baseFare = 13.0; // first 5 km
    const double perKmRate = 2.25; // succeeding km

    if (distanceKm <= 5) {
      return baseFare;
    } else {
      return baseFare + ((distanceKm - 5) * perKmRate);
    }
  }

  static String formatFare(double fare) {
    return '₱${fare.toStringAsFixed(2)}';
  }

  static Map<String, double> getMidpoint(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return {
      'latitude': (lat1 + lat2) / 2,
      'longitude': (lon1 + lon2) / 2,
    };
  }

  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double dLon = _toRadians(lon2 - lon1);
    double lat1Rad = _toRadians(lat1);
    double lat2Rad = _toRadians(lat2);

    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    double bearing = _atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  static String getCardinalDirection(double bearing) {
    const List<String> directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  static double _atan2(double y, double x) {
    if (x > 0) {
      return atan(y / x);
    } else if (x < 0 && y >= 0) {
      return atan(y / x) + pi;
    } else if (x < 0 && y < 0) {
      return atan(y / x) - pi;
    } else if (x == 0 && y > 0) {
      return pi / 2;
    } else if (x == 0 && y < 0) {
      return -pi / 2;
    } else {
      return 0;
    }
  }
}