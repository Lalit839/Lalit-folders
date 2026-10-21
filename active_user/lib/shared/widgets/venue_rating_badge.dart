import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class VenueRatingBadge extends StatelessWidget {
  final double rating;
  final int reviews;

  const VenueRatingBadge({
    super.key,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGreyBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // Top Green Block: Star + Rating Value
                Container(
                  height: 24,
                  color: AppColors.greenColor,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.bold(
                        rating.toStringAsFixed(1),
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, color: Colors.white, size: 9),
                    ],
                  ),
                ),
                // Bottom Black Block: "Google"
                Container(
                  height: 20,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: AppText.medium(
                    'Google',
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        AppText.medium(
          '$reviews ratings',
          fontSize: 9,
          color: AppColors.textPrimary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
