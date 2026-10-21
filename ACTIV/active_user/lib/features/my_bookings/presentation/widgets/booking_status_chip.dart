import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class BookingStatusChip extends StatelessWidget {
  final String status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isCancelled =
        status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'canceled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isCancelled
            ? Colors.black
            : AppColors.yellowDark, // Color(0xFF242B0D)
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: AppText.bold(
        status,
        color: isCancelled ? AppColors.errorRed : AppColors.primary,
        fontSize: 12,
      ),
    );
  }
}
