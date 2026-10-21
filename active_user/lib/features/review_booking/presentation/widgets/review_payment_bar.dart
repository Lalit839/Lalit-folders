import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class ReviewPaymentBar extends StatelessWidget {
  final double totalAmount;
  final String selectedPaymentMethod;
  final VoidCallback onPayPressed;

  const ReviewPaymentBar({
    super.key,
    required this.totalAmount,
    required this.selectedPaymentMethod,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toInt()}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'INR',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onPayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors
                    .surface, // Adjust to match design (dark button with green text)
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pay Now',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
