import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapManager {
  // Google Maps
  GoogleMapController? _mapController;
  Set<maps.Marker> _markers = {};

  GoogleMapController? get controller => _mapController;
  Set<maps.Marker> get markers => _markers;

  void setController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> animateToLocation(Position position) async {
    if(_mapController == null) return;

    final location = LatLng(position.latitude, position.longitude);
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
  }

  void updateUserMarker(Position position, Placemark? placemark) {
    final userLocation = LatLng(position.latitude, position.longitude);
    _markers = {
      maps.Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: placemark != null 
            ? '${placemark.street}, ${placemark.locality}' 
            : '',
        ),
      ),
    };
  }
}