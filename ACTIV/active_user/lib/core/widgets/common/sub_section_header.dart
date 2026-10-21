import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class SubSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final Color? iconColor;
  final double? fontSize;
  final String? prefixIcon;
  final String? suffixIcon;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final VoidCallback? onSeeAllTap;
  final String seeAllText;

  const SubSectionHeader({
    super.key,
    required this.title,
    this.color,
    this.iconColor,
    this.fontSize,
    this.prefixIcon,
    this.suffixIcon,
    this.trailingWidget,
    this.onTap,
    this.onSeeAllTap,
    this.seeAllText = 'See all',
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                AppSvg(
                  prefixIcon!,
                  width: 20,
                  height: 20,
                  color: iconColor ?? color ?? AppColors.greyBorder,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppText.bold(
                  title,
                  color: color ?? AppColors.greyBorder,
                  fontSize: fontSize ?? 18,
                ),
              ),
            ],
          ),
        ),
        if (trailingWidget != null)
          trailingWidget!
        else if (onSeeAllTap != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSeeAllTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.medium('See all', color: AppColors.greyBorder),
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
        if (suffixIcon != null)
          AppSvg(
            suffixIcon!,
            width: 24,
            height: 24,
            color: iconColor ?? color ?? AppColors.greyBorder,
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
