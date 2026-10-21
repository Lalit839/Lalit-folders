import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/models/coupon_ui_model.dart';

class CouponCard extends StatelessWidget {
  final CouponUiModel coupon;
  final VoidCallback onApply;
  final VoidCallback onInfoTap;
  final String actionLabel;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.onApply,
    required this.onInfoTap,
    this.actionLabel = 'Tap to apply',
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSvg(AppAssets.largeOfferTag2, width: 42, height: 42),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppText.bold(
                            coupon.title,
                            color: AppColors.textPrimary,
                            fontSize: 16)),
                        GestureDetector(
                          onTap: onInfoTap,
                          behavior: HitTestBehavior.opaque,
                          child: AppSvg(AppAssets.info)),
                      ]),
                    AppText(
                      coupon.subtitle,
                      color: AppColors.skyBlue),
                  ])),
            ]),
          AppDivider(verticalPadding: 16),
          GestureDetector(
            onTap: onApply,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: AppText.bold(
                actionLabel,
                color: AppColors.textPrimary,
                fontSize: 16))),
        ]));
  }
}
