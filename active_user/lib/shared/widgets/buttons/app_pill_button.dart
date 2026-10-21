import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class AppPillButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const AppPillButton({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.blackColor2
              : AppColors.blackColor2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.bold(
              title,
              color: isEnabled ? AppColors.primary : AppColors.grey99),
            const SizedBox(width: 8),
            AppSvg(
              AppAssets.thickArrowRight,
              color: isEnabled ? AppColors.primary : AppColors.grey99),
          ])));
  }
}
