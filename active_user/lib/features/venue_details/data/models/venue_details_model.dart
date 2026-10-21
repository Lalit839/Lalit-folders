import 'package:activ_user_app/core/utils/city_label.dart';

class VenueDetailsModel {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<VenueActivity> activities;
  final List<VenueOffer> offers;
  final List<VenueAmenity> amenities;
  final List<String> rules;
  final String cancellationPolicy;
  final List<VenueFaq> faqs;

  VenueDetailsModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.activities,
    required this.offers,
    required this.amenities,
    required this.rules,
    required this.cancellationPolicy,
    required this.faqs,
  });

  factory VenueDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawActivities = (json['activities'] as List<dynamic>?) ?? [];
    final activities = rawActivities.map((raw) {
      final value =
          raw is Map<String, dynamic> && raw['activity'] is Map<String, dynamic>
          ? raw['activity'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return VenueActivity.fromJson(value);
    }).toList();
    return VenueDetailsModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'ACTIV Venue',
      address: venueLocationLabel(json),
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      activities: activities,
      offers:
          (json['offers'] as List<dynamic>?)
              ?.map((e) => VenueOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => VenueAmenity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rules: List<String>.from(json['rules'] ?? []),
      cancellationPolicy: json['cancellationPolicy'] as String? ?? '',
      faqs:
          (json['faqs'] as List<dynamic>?)
              ?.map((e) => VenueFaq.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      id: json['id'] as String,
      name: json['name'] as String,
      sportCode: json['sportCode'] as String? ?? '',
      iconAsset: json['iconAsset'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      variations: List<String>.from(json['variations'] ?? []),
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
      id: json['id'] as String,
      activityName: json['activityName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
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

  factory VenueAmenity.fromJson(Map<String, dynamic> json) {
    return VenueAmenity(
      name: json['name'] as String,
      iconAsset: json['iconAsset'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
    );
  }
}

class VenueFaq {
  final String question;
  final String answer;

  VenueFaq({required this.question, required this.answer});

  factory VenueFaq.fromJson(Map<String, dynamic> json) {
    return VenueFaq(
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}
