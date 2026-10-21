import 'package:activ_user_app/core/widgets/image/app_svg_network.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class SportCategoryCard extends StatelessWidget {
  final String label;
  final String iconPath;
  final String iconUrl;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const SportCategoryCard({
    super.key,
    required this.label,
    required this.iconPath,
    this.iconUrl = '',
    this.onTap,
    this.width = 84,
    this.height = 120,
    this.margin = const EdgeInsets.only(right: 10),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: width ?? 84),
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.transparentGrey, // rgba(34, 34, 34, 0)
              AppColors.yellowColor, // #DAFF50
            ],
          ),
        ),
        padding: const EdgeInsets.all(1), // 1px solid border
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background, // #0D0D0D
                AppColors.yellowDark, // #242B0D
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Expanded(
                child: Center(
                  child: iconUrl.isNotEmpty
                      ? AppSvgNetwork(
                          iconUrl,
                          width: 80,
                          height: 80,
                          fallbackAsset: iconPath,
                        )
                      : iconPath.endsWith('.svg')
                          ? AppSvg(iconPath, width: 80, height: 80)
                          : Image.asset(iconPath, width: 80, height: 80),
                ),
              ),
              const SizedBox(height: 8),
              // Text Label
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AppText.medium(
                  label.replaceAll(' ', '\n'),
                  color: AppColors.greyBorder,
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
