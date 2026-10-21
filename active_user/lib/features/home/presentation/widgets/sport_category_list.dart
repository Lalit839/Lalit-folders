import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/features/home/presentation/widgets/sport_category_card.dart';

class SportCategoryList extends StatelessWidget {
  final List<Map<String, String>> categories;
  final ValueChanged<int>? onCategoryTap;
  final VoidCallback? onViewAllTap;

  const SportCategoryList({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool showViewAll = onViewAllTap != null;
    final sourceCategories = categories.isNotEmpty
        ? categories
        : mergeAssetSportCategories(const <Map<String, String>>[]);
    final visibleCategories = sourceCategories.take(7).toList();
    final itemCount = visibleCategories.length + (showViewAll ? 1 : 0);
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (showViewAll && index == visibleCategories.length) {
            return _buildViewAllCard(context);
          }
          final category = visibleCategories[index];
          return SportCategoryCard(
            label: category['label'] ?? '',
            iconPath: category['iconPath'] ?? '',
            iconUrl: category['iconUrl'] ?? '',
            onTap: () => onCategoryTap?.call(index),
          );
        },
      ),
    );
  }

  Widget _buildViewAllCard(BuildContext context) {
    return GestureDetector(
      onTap: onViewAllTap,
      child: Container(
        width: 84,
        height: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.transparentGrey, AppColors.primary],
          ),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: const Color(
              0xFF161616,
            ), // Dark background matching the image
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.background,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppText.medium(
                'View All\nSports',
                color: AppColors.greyBorder,
                fontSize: 14,
                textAlign: TextAlign.center,
                maxLines: 2,
                height: 1.2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
