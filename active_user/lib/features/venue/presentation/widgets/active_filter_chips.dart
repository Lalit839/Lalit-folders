import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';

class ActiveFilterChips extends StatelessWidget {
  final List<String> activeFilters;
  final ValueChanged<String>? onClearFilter;
  final VoidCallback? onFilterButtonPressed;

  const ActiveFilterChips({
    super.key,
    required this.activeFilters,
    this.onClearFilter,
    this.onFilterButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onFilterButtonPressed,
            child: _buildFilterChip(
              icon: AppAssets.filter,
              label: 'Filters',
              isActive: false,
            ),
          ),
          const SizedBox(width: 12),
          Container(height: 24, width: 1, color: AppColors.lightGreyBorder),
          if (activeFilters.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activeFilters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: _buildFilterChip(
                        label: filter,
                        onClear: () {
                          if (onClearFilter != null) {
                            onClearFilter!(filter);
                          }
                        },
                        isActive: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    String? icon,
    required String label,
    VoidCallback? onClear,
    bool isActive = false,
  }) {
    return Container(
      decoration: isActive
          ? null
          : BoxDecoration(
              color: AppColors.blackColor2,
              borderRadius: BorderRadius.circular(40),
            ),
      child: AppGradientContainer(
        isSelected: isActive,
        borderRadius: 42,
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[AppSvg(icon), const SizedBox(width: 12)],
            AppText.medium(
              label,
              color: isActive
                  ? AppColors.yellowColorLight
                  : AppColors.textPrimary,
              fontSize: 14,
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  color: isActive
                      ? AppColors.yellowColorLight
                      : AppColors.textPrimary,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
