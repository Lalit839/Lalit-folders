import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class VenueResultsHeader extends StatelessWidget {
  final int totalVenues;

  const VenueResultsHeader({super.key, required this.totalVenues});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          AppText.medium(
            'Total Venues: $totalVenues',
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ],
      ),
    );
  }
}
