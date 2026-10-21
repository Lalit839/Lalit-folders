import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_strings.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blackColor2,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey2, width: 1.0))),
      padding: EdgeInsets.only(
        top: 4.0,
        bottom: bottomPadding > 0 ? bottomPadding : 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            iconPath: AppAssets.navHome,
            label: AppStrings.navHome),
          _buildNavItem(
            index: 1,
            iconPath: AppAssets.navBookings,
            label: AppStrings.navBookings),
          _buildNavItem(
            index: 2,
            iconPath: AppAssets.navCalendar,
            label: AppStrings.navCalendar),
          _buildNavItem(
            index: 3,
            iconPath: AppAssets.savedVenue,
            label: AppStrings.navSavedVenues),
        ]));
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.grey99;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvg(
                iconPath,
                width: 40,
                height: 40,
                color: isSelected ? activeColor : inactiveColor),
              const SizedBox(height: 4),
              AppText.medium(
                label,
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            ]))));
  }
}
