import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class SelectedCourtItem extends StatelessWidget {
  final String courtName;
  final String type;
  final String format;
  final double price;

  const SelectedCourtItem({
    super.key,
    required this.courtName,
    required this.type,
    required this.format,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.medium(courtName, color: AppColors.textPrimary),
              const SizedBox(height: 2),
              AppText(
                '$type  |  $format',
                color: AppColors.textGrey),
            ]),
          AppText.bold(
            '₹${price.toInt()}',
            color: AppColors.textPrimary,
            fontSize: 16),
        ]));
  }
}
