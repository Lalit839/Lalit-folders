import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/venue_rating_badge.dart';

class VenueSharePreview extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String sports;
  final String location;
  final double rating;
  final int reviewCount;

  const VenueSharePreview({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.sports,
    required this.location,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity,
              height: 240,
              color: AppColors.lightGreyBorder,
              child: const Icon(Icons.image, color: AppColors.greyBorder)))),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bold(
                    name,
                    color: AppColors.white,
                    fontSize: 20),
                  const SizedBox(height: 4),
                  AppText(
                    '$sports | $location',
                    color: AppColors.greyBorder),
                ])),
            const SizedBox(width: 16),
            VenueRatingBadge(rating: rating, reviews: reviewCount),
          ]),
      ]);
  }
}
