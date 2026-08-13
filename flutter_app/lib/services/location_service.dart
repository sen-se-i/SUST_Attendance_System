import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? error;

  LocationResult({required this.latitude, required this.longitude, this.error});
}

class LocationService {
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        error: 'Location services are disabled on your device. Please turn GPS on.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(
          latitude: 0,
          longitude: 0,
          error: 'Location permission denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        error: 'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        error: 'Could not read your current GPS location. Please keep location enabled and try again outdoors or near a window.',
      );
    }
  }

  static double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000.0;
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLon = (lon2 - lon1) * (pi / 180.0);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }
}
