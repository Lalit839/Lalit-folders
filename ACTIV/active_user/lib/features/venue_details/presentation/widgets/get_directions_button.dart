import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class GetDirectionsButton extends StatelessWidget {
  final VoidCallback onTap;

  const GetDirectionsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.blackColor2,
          borderRadius: BorderRadius.circular(48),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvg(AppAssets.directions),
            const SizedBox(width: 8),
            AppText.small(
              'Get Directions',
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ],
        ),
      ),
    );
  }
}
