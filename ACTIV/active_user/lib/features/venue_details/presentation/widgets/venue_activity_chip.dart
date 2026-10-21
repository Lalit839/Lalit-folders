import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';
import 'package:activ_user_app/core/widgets/image/app_svg_network.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class VenueActivityChip extends StatelessWidget {
  final VenueActivity activity;
  final bool isSelected;
  final VoidCallback onTap;

  const VenueActivityChip({
    super.key,
    required this.activity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = isSelected
        ? AppColors.yellowColorLight
        : AppColors.textPrimary;
    final iconUrl = activity.iconUrl.trim();
    final fallbackAsset = activity.iconAsset.isNotEmpty
        ? activity.iconAsset
        : iconForSport(
            activity.sportCode.isNotEmpty ? activity.sportCode : activity.name,
          );
    final hasIcon = iconUrl.isNotEmpty || fallbackAsset.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? null
            : BoxDecoration(
                color: AppColors.blackColor2,
                borderRadius: BorderRadius.circular(48),
              ),
        child: AppGradientContainer(
          isSelected: isSelected,
          borderRadius: 48,
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon)
                _ActivityIcon(
                  iconUrl: iconUrl,
                  fallbackAsset: fallbackAsset,
                  tint: tint,
                ),
              if (hasIcon) const SizedBox(width: 6),
              AppText.medium(activity.name, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  final String iconUrl;
  final String fallbackAsset;
  final Color tint;

  const _ActivityIcon({
    required this.iconUrl,
    required this.fallbackAsset,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    if (fallbackAsset.isNotEmpty) {
      return _AssetActivityIcon(asset: fallbackAsset, tint: tint);
    }

    if (iconUrl.toLowerCase().endsWith('.svg')) {
      return AppSvgNetwork(
        iconUrl,
        width: 24,
        height: 24,
        color: tint,
        fallbackAsset: fallbackAsset,
      );
    }

    return const SizedBox(width: 24, height: 24);
  }
}

class _AssetActivityIcon extends StatelessWidget {
  final String asset;
  final Color tint;

  const _AssetActivityIcon({required this.asset, required this.tint});

  @override
  Widget build(BuildContext context) {
    if (asset.toLowerCase().endsWith('.svg')) {
      return AppSvg(asset, width: 24, height: 24, color: tint);
    }

    return Image.asset(
      asset,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox(width: 24, height: 24),
    );
  }
}
