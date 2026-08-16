import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
  final String? error;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    this.error,
  });
}

class LocationService {
  static Future<LocationResult> getCurrentLocation({double radiusMeters = 20.0}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        accuracyMeters: double.infinity,
        capturedAt: DateTime.now().toUtc(),
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
          accuracyMeters: double.infinity,
          capturedAt: DateTime.now().toUtc(),
          error: 'Location permission denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        accuracyMeters: double.infinity,
        capturedAt: DateTime.now().toUtc(),
        error: 'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    try {
      Position? best;
      final targetAccuracyMeters = max(3.0, radiusMeters);

      for (int i = 0; i < 6; i++) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 6),
        );

        if (best == null || position.accuracy < best.accuracy) {
          best = position;
        }
        if (position.accuracy <= targetAccuracyMeters) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 700));
      }

      final position = best;
      if (position == null) {
        throw Exception('No GPS fix returned');
      }

      if (position.accuracy > targetAccuracyMeters) {
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          capturedAt: (position.timestamp ?? DateTime.now()).toUtc(),
          error: 'GPS accuracy is ${position.accuracy.toStringAsFixed(1)}m, but this session needs ${targetAccuracyMeters.toStringAsFixed(1)}m or better. Stand still near a window and try again.',
        );
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: (position.timestamp ?? DateTime.now()).toUtc(),
      );
    } catch (e) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        accuracyMeters: double.infinity,
        capturedAt: DateTime.now().toUtc(),
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

