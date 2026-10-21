import 'package:activ_user_app/core/utils/city_label.dart';

class VenueDetailsModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<VenueActivity> activities;
  final List<VenueFacility> facilities;
  final List<VenueOffer> offers;
  final List<VenueAmenity> amenities;
  final List<String> services;
  final List<String> operatingHours;
  final String contactEmail;
  final String contactPhone;
  final List<String> rules;
  final String cancellationPolicy;
  final List<VenueFaq> faqs;

  VenueDetailsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.activities,
    required this.facilities,
    required this.offers,
    required this.amenities,
    required this.services,
    required this.operatingHours,
    required this.contactEmail,
    required this.contactPhone,
    required this.rules,
    required this.cancellationPolicy,
    required this.faqs,
  });

  factory VenueDetailsModel.fromJson(Map<String, dynamic> json) {
    final activities = _list(json['activities'])
        .map((raw) {
          final rawMap = _map(raw);
          final value = _map(rawMap?['activity']) ?? rawMap;
          return value == null ? null : VenueActivity.fromJson(value);
        })
        .whereType<VenueActivity>()
        .toList();
    return VenueDetailsModel(
      id: json['id']?.toString() ?? '',
      name: _string(json['name'], fallback: 'ACTIV Venue'),
      description: _string(json['description']),
      address: venueLocationLabel(json),
      distance: _double(json['distance']),
      rating: _double(json['rating']),
      reviewCount: _int(json['reviewCount']),
      imageUrls: _imageUrls(json),
      activities: activities,
      facilities: _list(json['facilities'])
          .map(_map)
          .whereType<Map<String, dynamic>>()
          .map(VenueFacility.fromJson)
          .toList(),
      offers: _list(json['offers'])
          .map(_map)
          .whereType<Map<String, dynamic>>()
          .map(VenueOffer.fromJson)
          .toList(),
      amenities: _list(
        json['amenities'],
      ).map(VenueAmenity.fromJsonValue).whereType<VenueAmenity>().toList(),
      services: _stringList(json['services']),
      operatingHours: _operatingHoursForVenue(json),
      contactEmail: _string(json['contactEmail']),
      contactPhone: _string(json['contactPhoneE164'] ?? json['venuePhone']),
      rules: _stringList(json['rules']),
      cancellationPolicy: _string(json['cancellationPolicy']),
      faqs: _list(json['faqs'])
          .map(_map)
          .whereType<Map<String, dynamic>>()
          .map(VenueFaq.fromJson)
          .toList(),
    );
  }

  static List<dynamic> _list(Object? value) {
    return value is List ? value : const [];
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(Object? value) {
    return _list(value).map((item) => item?.toString() ?? '').where((item) {
      return item.trim().isNotEmpty;
    }).toList();
  }

  static List<String> _imageUrls(Map<String, dynamic> json) {
    final urls = _stringList(json['imageUrls']);
    if (urls.isNotEmpty) return urls;

    final images = _list(json['images'])
        .map(_map)
        .whereType<Map<String, dynamic>>()
        .map((image) {
          return _string(
            image['url'] ?? image['imageUrl'] ?? image['src'] ?? image['path'],
          );
        })
        .where((url) => url.isNotEmpty)
        .toList();
    if (images.isNotEmpty) return images;

    final image = _string(json['image'] ?? json['imagePath']);
    return image.isEmpty ? const [] : [image];
  }

  static List<String> _operatingHours(Object? value) {
    final directList = _stringList(value);
    if (directList.isNotEmpty) return directList;

    final map = _map(value);
    if (map == null) return const [];

    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final keys = [
      ...dayOrder.where(map.containsKey),
      ...map.keys.where((key) => !dayOrder.contains(key.toLowerCase())),
    ];

    return keys
        .map((key) {
          final value = map[key];
          final label = _titleCase(key);
          if (value is Map) {
            final open = _string(value['open'] ?? value['openingTime']);
            final close = _string(value['close'] ?? value['closingTime']);
            final closed = value['closed'] == true;
            if (closed) return '$label: Closed';
            if (open.isNotEmpty || close.isNotEmpty) {
              return '$label: ${[open, close].where((item) => item.isNotEmpty).join(' - ')}';
            }
          }
          final text = value?.toString().trim() ?? '';
          return text.isEmpty ? '' : '$label: $text';
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static List<String> _operatingHoursForVenue(Map<String, dynamic> json) {
    final hours = _operatingHours(json['operatingHours']);
    if (hours.isNotEmpty) return hours;

    final availability = _map(json['availability']);
    if (availability == null) return const [];

    final byDay = <String, Set<String>>{};
    for (final rawEntries in availability.values) {
      for (final rawEntry in _list(rawEntries)) {
        final entry = _map(rawEntry);
        if (entry == null) continue;
        final day = _string(entry['day']);
        if (day.isEmpty) continue;
        final ranges = byDay.putIfAbsent(day.toLowerCase(), () => <String>{});
        for (final rawSlot in _list(entry['slots'])) {
          final slot = _map(rawSlot);
          if (slot == null) continue;
          final open = _string(slot['openTime'] ?? slot['open']);
          final close = _string(slot['closeTime'] ?? slot['close']);
          if (open.isNotEmpty && close.isNotEmpty) {
            ranges.add('$open - $close');
          }
        }
      }
    }

    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return [
          ...dayOrder.where(byDay.containsKey),
          ...byDay.keys.where((day) => !dayOrder.contains(day)),
        ]
        .map((day) {
          final ranges = byDay[day]?.toList() ?? const [];
          ranges.sort();
          return ranges.isEmpty
              ? ''
              : '${_titleCase(day)}: ${ranges.join(', ')}';
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _titleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
}

class VenueFacility {
  final String id;
  final String name;
  final String activityId;
  final int capacity;

  VenueFacility({
    required this.id,
    required this.name,
    required this.activityId,
    required this.capacity,
  });

  factory VenueFacility.fromJson(Map<String, dynamic> json) {
    return VenueFacility(
      id: json['id']?.toString() ?? '',
      name: VenueDetailsModel._string(json['name'], fallback: 'Facility'),
      activityId: json['activityId']?.toString() ?? '',
      capacity: VenueDetailsModel._int(json['capacity']),
    );
  }
}

class VenueActivity {
  final String id;
  final String name;
  final String sportCode;
  final String iconAsset;
  final String iconUrl;
  final List<String> variations;

  VenueActivity({
    required this.id,
    required this.name,
    required this.sportCode,
    required this.iconAsset,
    required this.iconUrl,
    required this.variations,
  });

  factory VenueActivity.fromJson(Map<String, dynamic> json) {
    return VenueActivity(
      id: json['id']?.toString() ?? '',
      name: VenueDetailsModel._string(json['name'], fallback: 'Activity'),
      sportCode: VenueDetailsModel._string(json['sportCode']),
      iconAsset: VenueDetailsModel._string(json['iconAsset']),
      iconUrl: VenueDetailsModel._string(json['iconUrl']),
      variations: VenueDetailsModel._stringList(json['variations']),
    );
  }
}

class VenueOffer {
  final String id;
  final String activityName;
  final String title;
  final String description;

  VenueOffer({
    required this.id,
    required this.activityName,
    required this.title,
    required this.description,
  });

  factory VenueOffer.fromJson(Map<String, dynamic> json) {
    return VenueOffer(
      id: json['id']?.toString() ?? '',
      activityName: VenueDetailsModel._string(json['activityName']),
      title: VenueDetailsModel._string(json['title']),
      description: VenueDetailsModel._string(json['description']),
    );
  }
}

class VenueAmenity {
  final String name;
  final String iconAsset;
  final String iconUrl;

  VenueAmenity({
    required this.name,
    required this.iconAsset,
    required this.iconUrl,
  });

  static VenueAmenity? fromJsonValue(Object? value) {
    if (value is String) {
      final name = value.trim();
      if (name.isEmpty) return null;
      return VenueAmenity(name: name, iconAsset: '', iconUrl: '');
    }
    final json = VenueDetailsModel._map(value);
    return json == null ? null : VenueAmenity.fromJson(json);
  }

  factory VenueAmenity.fromJson(Map<String, dynamic> json) {
    return VenueAmenity(
      name: VenueDetailsModel._string(
        json['name'] ?? json['label'] ?? json['title'],
      ),
      iconAsset: VenueDetailsModel._string(json['iconAsset']),
      iconUrl: VenueDetailsModel._string(json['iconUrl']),
    );
  }
}

class VenueFaq {
  final String question;
  final String answer;

  VenueFaq({required this.question, required this.answer});

  factory VenueFaq.fromJson(Map<String, dynamic> json) {
    return VenueFaq(
      question: VenueDetailsModel._string(json['question']),
      answer: VenueDetailsModel._string(json['answer']),
    );
  }
}
