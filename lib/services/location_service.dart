import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static double? _cachedLat;
  static double? _cachedLng;
  static String? _cachedAddress;

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Step 1 — Check if GPS is ON
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS is OFF on device');
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return null;
      }

      // Step 2 — Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('After request: $permission');
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permission permanently denied');
        // Open app settings so user can manually enable
        await Geolocator.openAppSettings();
        return null;
      }

      // Step 3 — Get real GPS position
      debugPrint('Getting position...');
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );

      debugPrint('Got position: ${pos.latitude}, ${pos.longitude}');
      _cachedLat = pos.latitude;
      _cachedLng = pos.longitude;

      // Step 4 — Reverse geocode
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          _cachedAddress = parts.join(', ');
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
        _cachedAddress =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      return {
        'lat': _cachedLat,
        'lng': _cachedLng,
        'address': _cachedAddress ?? 'Location found',
      };
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }

  static String getMapsUrl(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';

  static double? get cachedLat => _cachedLat;
  static double? get cachedLng => _cachedLng;
  static String? get cachedAddress => _cachedAddress;
}