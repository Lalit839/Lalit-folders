import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllTap;
  final bool showSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllTap,
    this.showSeeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.medium(title, fontSize: 20, color: AppColors.textPrimary),
        if (showSeeAll)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSeeAllTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.medium(
                  'See all',
                  color: AppColors.greyBorder,
                  fontSize: 16,
                ),
                const SizedBox(width: 4),
                AppSvg(
                  AppAssets.thickArrowRight,
                  width: 24,
                  height: 24,
                  color: AppColors.greyBorder,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
