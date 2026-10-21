import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class NotificationEmptyView extends StatelessWidget {
  const NotificationEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        // By wrapping the column in a Transform, we can nudge it upwards.
        // It's a common UI design rule that empty states should sit slightly
        // above the mathematical center (optical centering) to look balanced.
        child: Transform.translate(
          offset: const Offset(0, -60), // Nudge up by 60 pixels
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvg(AppAssets.largeNotification),

              // const SizedBox(height: 32),
              AppText.bold(
                "You're All Caught Up!",
                fontSize: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 8),
              AppText.medium(
                'Check back later for new notifications.',
                color: AppColors.grey99,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
