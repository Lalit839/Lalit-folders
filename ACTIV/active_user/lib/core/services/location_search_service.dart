import 'dart:async';

import 'package:activ_user_app/core/models/selected_location.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearchService {
  LocationSearchService._();

  static final instance = LocationSearchService._();

  final Map<String, List<PlaceSuggestion>> _cache = {};

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];
    final cached = _cache[normalized];
    if (cached != null) return cached;

    final result = await ActivApiClient.instance.searchLocations(query);
    final seen = <String>{};
    final suggestions = (result['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _suggestionFromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.mainText.isNotEmpty)
        .where((item) => seen.add(_dedupeKey(item)))
        .toList();
    _cache[normalized] = suggestions;
    return suggestions;
  }

  Future<SelectedLocation> detailsForSuggestion(
    PlaceSuggestion suggestion,
  ) async {
    final lat = suggestion.latitude;
    final lng = suggestion.longitude;
    if (lat == null || lng == null) {
      throw Exception('Location details are missing coordinates');
    }

    return SelectedLocation(
      displayName:
          suggestion.raw['displayName']?.toString() ??
          [
            suggestion.mainText,
            if (suggestion.secondaryText.isNotEmpty) suggestion.secondaryText,
          ].join(', '),
      city: suggestion.raw['city']?.toString(),
      locality: suggestion.raw['locality']?.toString(),
      district: suggestion.raw['district']?.toString(),
      state: suggestion.raw['state']?.toString(),
      country: suggestion.raw['country']?.toString(),
      countryCode: suggestion.raw['countryCode']?.toString(),
      postalCode: suggestion.raw['postalCode']?.toString(),
      latitude: lat,
      longitude: lng,
      placeId: suggestion.placeId,
    );
  }

  Future<SelectedLocation> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final data = await ActivApiClient.instance.reverseLocation(
        latitude: latitude,
        longitude: longitude,
      ).timeout(const Duration(seconds: 4));
      final location = _selectedLocationFromJson(data, latitude, longitude);
      if (location != null && location.displayName != 'Current location') {
        return location;
      }
    } catch (_) {}

    final deviceLocation = await _reverseGeocodeWithDevice(
      latitude,
      longitude,
    );
    if (deviceLocation != null &&
        deviceLocation.displayName != 'Current location') {
      return deviceLocation;
    }

    if (deviceLocation != null) return deviceLocation;

    return SelectedLocation(
      displayName: 'Current location',
      country: 'India',
      countryCode: 'IN',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<SelectedLocation?> _reverseGeocodeWithDevice(
    double latitude,
    double longitude,
  ) async {
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final city = _firstNonEmpty([
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]);
      final locality = _bestLocality(place, city);
      final display = _joinLocationParts([
        locality,
        if (city != null && city != locality) city,
        place.administrativeArea,
      ]);
      return SelectedLocation(
        displayName: display ?? 'Current location',
        city: city,
        locality: locality,
        subLocality: place.subLocality,
        district: place.subAdministrativeArea,
        state: place.administrativeArea,
        country: place.country,
        countryCode: place.isoCountryCode,
        postalCode: place.postalCode,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return null;
    }
  }

  String? _bestLocality(Placemark place, String? city) {
    final name = place.name?.trim();
    final street = place.street?.trim();
    return _firstNonEmpty([
      place.subLocality,
      if (name != null && name != street && name != city) name,
      place.thoroughfare,
      city,
    ]);
  }

  SelectedLocation? _selectedLocationFromJson(
    Map<String, dynamic> json,
    double fallbackLatitude,
    double fallbackLongitude,
  ) {
    if (json.isEmpty) return null;
    final latitude = (json['latitude'] as num?)?.toDouble() ?? fallbackLatitude;
    final longitude =
        (json['longitude'] as num?)?.toDouble() ?? fallbackLongitude;
    final locality = json['locality']?.toString();
    final city = json['city']?.toString();
    final main = json['mainText']?.toString();
    final display = _firstNonEmpty([
      _joinLocationParts([
        locality,
        if (city != null && city != locality) city,
        json['state']?.toString(),
      ]),
      json['displayName']?.toString(),
      main,
    ]);
    return SelectedLocation(
      displayName: display ?? 'Current location',
      city: city,
      locality: locality ?? main,
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      countryCode: json['countryCode']?.toString(),
      postalCode: json['postalCode']?.toString(),
      latitude: latitude,
      longitude: longitude,
      placeId: json['placeId']?.toString(),
    );
  }

  PlaceSuggestion _suggestionFromJson(Map<String, dynamic> json) {
    final displayName = json['displayName']?.toString();
    return PlaceSuggestion(
      placeId: json['placeId']?.toString() ?? '',
      mainText:
          json['mainText']?.toString() ??
          displayName?.split(',').first ??
          '',
      secondaryText: json['secondaryText']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      raw: json,
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String? _joinLocationParts(List<String?> values) {
    final parts = values
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String _dedupeKey(PlaceSuggestion item) {
    final text = '${item.mainText}|${item.secondaryText}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final lat = item.latitude == null
        ? ''
        : (item.latitude! * 100).roundToDouble() / 100;
    final lng = item.longitude == null
        ? ''
        : (item.longitude! * 100).roundToDouble() / 100;
    return '$text|$lat|$lng';
  }
}
