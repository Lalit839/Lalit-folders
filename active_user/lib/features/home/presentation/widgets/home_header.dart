import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';

class HomeHeader extends StatelessWidget {
  final String? userName;
  final String currentLocation;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showUnreadDot;

  const HomeHeader({
    super.key,
    this.userName,
    this.currentLocation = 'Chandra nagar, central',
    this.onLocationTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.showUnreadDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // User Info & Location Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bold(
                'Hi, ${userName ?? SharedPrefService.userName ?? 'User'}',
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1.0,
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvg(
                      AppAssets.location,
                      color: AppColors.primary,
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AppText.medium(
                        currentLocation,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        maxLines: 1,
                        height: 1.0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    AppSvg(
                      AppAssets.downArrow,
                      color: AppColors.textPrimary,
                      height: 24,
                      width: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Action Buttons: Notifications & Profile
        GestureDetector(
          onTap: onNotificationTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppSvg(
                  AppAssets.notification,
                  color: AppColors.textGrey,
                  height: 26,
                  width: 26,
                ),
                // Unread indicator dot
                if (showUnreadDot)
                  Positioned(
                    top: 6,
                    right: 13,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: AppSvg(
              AppAssets.navProfile,
              color: AppColors.textGrey,
              height: 30,
              width: 30,
            ),
          ),
        ),
      ],
    );
  }
}
