import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled on the device
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check current location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission from the user
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Convert latitude and longitude into readable city/area text
  static Future<String> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Match Figma format: Chandra Nagar, Central or SubLocality, Locality
        final String area = place.subLocality ?? place.name ?? '';
        final String city = place.locality ?? '';

        if (area.isNotEmpty && city.isNotEmpty) {
          return '$area, $city';
        } else if (city.isNotEmpty) {
          return city;
        } else if (area.isNotEmpty) {
          return area;
        }
      }
    } catch (e) {
      // Silently catch geocoding errors (e.g. offline/timeout) and fallback
    }
    return 'Current location';
  }

  // Determine current position, handling permissions and service checks.
  // Returns a Position if successful, or throws a descriptive String error.
  static Future<Position> getCurrentLocation() async {
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions were denied by user.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. Please enable them in your device settings.';
    }

    bool serviceEnabled = await isLocationEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled on your device.';
    }

    // Permission is granted, fetch position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Open device settings so user can manually enable permissions
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Open location settings so user can manually enable GPS
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
