import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/venue_rating_badge.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/get_directions_button.dart';

class VenueBasicInfo extends StatelessWidget {
  final String name;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final VoidCallback onGetDirectionsTap;

  const VenueBasicInfo({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.onGetDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.medium(name, color: AppColors.white, fontSize: 22),
              const SizedBox(height: 8),
              AppText.small(
                address,
                color: AppColors.grey99,
                fontSize: 16, // Adjusted slightly to look good
              ),
              const SizedBox(height: 20),
              GetDirectionsButton(onTap: onGetDirectionsTap),
            ],
          ),
        ),
        const SizedBox(width: 24),
        VenueRatingBadge(rating: rating, reviews: reviewCount),
      ],
    );
  }
}
