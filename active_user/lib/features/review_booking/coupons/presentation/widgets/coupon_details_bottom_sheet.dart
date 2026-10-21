import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/models/coupon_ui_model.dart';

class CouponDetailsBottomSheet extends StatelessWidget {
  final CouponUiModel coupon;
  final VoidCallback onApply;

  const CouponDetailsBottomSheet({
    super.key,
    required this.coupon,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 0.0,
        bottom: 40),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bold(
            coupon.title,
            color: AppColors.textPrimary,
            fontSize: 18),
          const SizedBox(height: 4),
          AppText(
            coupon.subtitle,
            color: AppColors.skyBlue,
            fontSize: 14),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8)),
              child: AppText.bold(
                coupon.code,
                color: AppColors.primary,
                fontSize: 16))),
          AppDivider(verticalPadding: 18),
          AppText.medium(
            'Terms & conditions',
            color: AppColors.textPrimary),
          const SizedBox(height: 16),
          _buildTerm('Valid on minimum order value ?'),
          _buildTerm('Valid three times per user during campaign period'),
          _buildTerm('Platform shall apply'),
        ]));
  }

  Widget _buildTerm(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 8.0),
            child: CircleAvatar(radius: 2, backgroundColor: AppColors.grey99)),
          Expanded(
            child: AppText(
              text,
              color: AppColors.grey99,
              fontSize: 16)),
        ]));
  }
}
