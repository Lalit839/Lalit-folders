class SelectedLocation {
  final String displayName;
  final String? city;
  final String? locality;
  final String? subLocality;
  final String? district;
  final String? state;
  final String? stateCode;
  final String? country;
  final String? countryCode;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? cityCode;

  const SelectedLocation({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.locality,
    this.subLocality,
    this.district,
    this.state,
    this.stateCode,
    this.country,
    this.countryCode,
    this.postalCode,
    this.placeId,
    this.cityCode,
  });

  String get headerLabel {
    final primary = locality?.trim().isNotEmpty == true
        ? locality!.trim()
        : city?.trim();
    final secondary = state?.trim();
    if (primary != null && primary.isNotEmpty) {
      if (secondary != null && secondary.isNotEmpty) {
        return '$primary, $secondary';
      }
      return primary;
    }
    return displayName;
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'city': city,
    'locality': locality,
    'subLocality': subLocality,
    'district': district,
    'state': state,
    'stateCode': stateCode,
    'country': country,
    'countryCode': countryCode,
    'postalCode': postalCode,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
    'cityCode': cityCode,
  };

  factory SelectedLocation.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const FormatException('Selected location is missing coordinates.');
    }
    return SelectedLocation(
      displayName: json['displayName']?.toString() ?? 'Selected location',
      city: json['city']?.toString(),
      locality: json['locality']?.toString(),
      subLocality: json['subLocality']?.toString(),
      district: json['district']?.toString(),
      state: json['state']?.toString(),
      stateCode: json['stateCode']?.toString(),
      country: json['country']?.toString(),
      countryCode: json['countryCode']?.toString(),
      postalCode: json['postalCode']?.toString(),
      latitude: latitude,
      longitude: longitude,
      placeId: json['placeId']?.toString(),
      cityCode: json['cityCode']?.toString(),
    );
  }
}

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> raw;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.raw,
    this.latitude,
    this.longitude,
  });
}
