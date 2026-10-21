import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class PaymentSummaryCard extends StatelessWidget {
  final String title;
  final double basePrice;
  final double convenienceFee;
  final double taxRate; // e.g. 0.18 for 18% GST

  const PaymentSummaryCard({
    super.key,
    required this.title,
    required this.basePrice,
    this.convenienceFee = 40.0,
    this.taxRate = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    final double taxAmount = basePrice * taxRate;
    final double grandTotal = basePrice + convenienceFee + taxAmount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreyBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bold('Booking Details', color: AppColors.white),
          const SizedBox(height: 12),
          AppText.medium(title, color: AppColors.primary),
          const SizedBox(height: 8),
          const Divider(color: AppColors.lightGreyBorder, height: 24),
          _buildRow('Base Booking Rate', '₹${basePrice.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildRow('Convenience Fee', '₹${convenienceFee.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildRow('GST (18%)', '₹${taxAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.lightGreyBorder, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.medium('Total Amount', color: AppColors.white),
              AppText.medium(
                '₹${grandTotal.toStringAsFixed(2)}',
                color: AppColors.primary,
                fontSize: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, color: AppColors.textGrey),
        AppText(value, color: AppColors.textPrimary),
      ],
    );
  }
}
