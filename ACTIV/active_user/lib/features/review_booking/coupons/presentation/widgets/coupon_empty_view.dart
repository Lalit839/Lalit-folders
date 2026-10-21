import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class CouponEmptyView extends StatelessWidget {
  const CouponEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvg(AppAssets.noCoupon),
            const SizedBox(height: 32),

            AppText.bold(
              'No coupons available',
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            AppText.medium(
              'Check again soon to find on exciting deal.',
              color: AppColors.grey99,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
