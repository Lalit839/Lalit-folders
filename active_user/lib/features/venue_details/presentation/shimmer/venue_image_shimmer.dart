import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class VenueImageShimmer extends StatelessWidget {
  const VenueImageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(16)));
  }
}
