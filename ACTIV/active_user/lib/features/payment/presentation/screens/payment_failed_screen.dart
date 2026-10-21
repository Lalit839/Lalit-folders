import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/features/payment/presentation/widgets/payment_action_button.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String errorMessage;
  final double amount;

  const PaymentFailedScreen({
    super.key,
    required this.errorMessage,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString =
        '${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Failed Icon with Glow
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              AppText.bold(
                'Payment Failed',
                color: AppColors.white,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const AppText(
                'Your payment transaction could not be processed. Please check details and try again.',
                color: AppColors.textGrey,

                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Transaction Details Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.lightGreyBorder,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildReceiptRow('Reason', errorMessage),
                    const Divider(color: AppColors.lightGreyBorder, height: 24),
                    _buildReceiptRow(
                      'Amount Attempted',
                      '₹${amount.toStringAsFixed(2)}',
                    ),
                    const Divider(color: AppColors.lightGreyBorder, height: 24),
                    _buildReceiptRow('Date & Time', dateString),
                    const Divider(color: AppColors.lightGreyBorder, height: 24),
                    _buildReceiptRow(
                      'Status',
                      'FAILED',
                      valueColor: AppColors.error,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Try Again Button
              PaymentActionButton(
                text: 'Try Again',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.lightGreyBorder,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const AppText(
                    'Cancel Checkout',
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, color: AppColors.textGrey),
        Flexible(
          child: AppText(
            value,
            color: valueColor ?? AppColors.textPrimary,

            fontWeight: FontWeight.bold,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
