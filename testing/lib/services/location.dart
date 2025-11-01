import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

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

    if (permission == LocationPermission.denied){
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