import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class LocationListItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const LocationListItem({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 0,
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      leading: AppSvg(
        AppAssets.location,
        color: AppColors.yellowColorLight,
        height: 24,
        width: 24,
      ),
      title: AppText.small(title, color: AppColors.textPrimary, fontSize: 18),
      trailing:
          trailing ??
          AppSvg(
            AppAssets.forwardArrow,
            color: AppColors.white,
            height: 24,
            width: 24,
          ),
      onTap: onTap,
    );
  }
}
