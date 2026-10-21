import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class PromoBannerCard extends StatelessWidget {
  final String title;
  final String? image;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double? width;

  const PromoBannerCard({
    super.key,
    required this.title,
    this.image,
    this.gradientColors,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        const [AppColors.deepBlueGradient, AppColors.purpleGradient];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? math.min(341.0, MediaQuery.of(context).size.width - 32),
        height: 74,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: colors,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            // Left Graphic Illustration (56x56)
            if (image != null)
              Image.asset(image!, width: 56, height: 56, fit: BoxFit.contain)
            else
              AppSvg(
                AppAssets.radioButton,
                width: 56,
                height: 56,
                color: const Color(0xFF64B5F6),
              ),
            const SizedBox(width: 12),
            // Middle Text
            Expanded(
              child: AppText.bold(
                title,
                color: AppColors.textPrimary,
                fontSize: 18,
                height: 1.16, // 21px line height for 18px size
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Right Arrow (24x24)
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: AppSvg(
                  AppAssets.thickArrowRight,
                  width: 24,
                  height: 24,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
