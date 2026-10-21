import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/review_booking/presentation/models/price_breakdown_ui_model.dart';

class PriceBreakdownCard extends StatelessWidget {
  final PriceBreakdownUiModel breakdown;

  const PriceBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bold('Price Breakdown', color: AppColors.greyBorder),
              AppDivider(verticalPadding: 12),
              _buildRow('Slot Price', breakdown.slotPrice),
              const SizedBox(height: 8),
              _buildRow('Service Fee', breakdown.serviceFee),
              const SizedBox(height: 8),
              _buildRow(
                'You saved',
                -breakdown.discount,
                valueColor: AppColors.skyBlue,
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              _buildRow('Subtotal', breakdown.subtotal, isHighlight: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.yellowDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildRow(
                'GST (${breakdown.gstPercentage.toInt()}%)',
                breakdown.gstAmount,
                isHighlight: true,
              ),
              const SizedBox(height: 8),
              _buildRow(
                'Total',
                breakdown.totalAmount,
                isHighlight: true,
                valueColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    double value, {
    Color? valueColor,
    bool isHighlight = false,
  }) {
    final String formattedValue = value < 0
        ? '- ₹${value.abs().toInt()}'
        : '₹${value.toInt()}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          color: isHighlight ? AppColors.textPrimary : AppColors.greyBorder,
          fontSize: 18,
        ),
        AppText.medium(
          formattedValue,
          color:
              valueColor ??
              (isHighlight ? AppColors.textPrimary : AppColors.greyBorder),
          fontSize: 18,
        ),
      ],
    );
  }
}
