import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';

class AuthTrustBadges extends StatelessWidget {
  const AuthTrustBadges({super.key});

  Widget _buildFeatureItem(String iconAsset, String text) {
    return Column(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: const BoxDecoration(
            color: AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppSvg(
              iconAsset,
              width: 24,
              height: 24,
              color: AppColors.grey99,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey99,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 82, color: AppColors.lightGrey);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildFeatureItem(AppAssets.security, 'Secure and\nTrusted'),
        const SizedBox(width: 12),
        _buildDivider(),
        const SizedBox(width: 12),
        _buildFeatureItem(AppAssets.calendar, '1000+ Venues\nNear You'),
        const SizedBox(width: 12),
        _buildDivider(),
        const SizedBox(width: 12),
        _buildFeatureItem(AppAssets.location, 'Easy Booking\nExperience'),
      ],
    );
  }
}
