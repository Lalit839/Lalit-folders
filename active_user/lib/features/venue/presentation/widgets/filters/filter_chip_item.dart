import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showClearIcon;
  final VoidCallback? onClear;
  final Widget? prefixIcon;

  const FilterChipItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showClearIcon = true,
    this.onClear,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? null
            : BoxDecoration(
                color: AppColors.blackColor2,
                borderRadius: BorderRadius.circular(40),
              ),
        child: AppGradientContainer(
          isSelected: isSelected,
          borderRadius: 42,
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              AppText.medium(
                label,
                color: isSelected
                    ? AppColors.yellowColorLight
                    : AppColors.textPrimary,
                fontSize: 14,
              ),
              if (isSelected && showClearIcon) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear ?? onTap,
                  child: AppSvg(
                    AppAssets.close,
                    height: 16,
                    width: 16,
                    color: AppColors.yellowColorLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
