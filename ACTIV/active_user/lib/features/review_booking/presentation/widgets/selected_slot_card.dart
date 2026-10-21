import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class SelectedSlotCard extends StatelessWidget {
  final String userName;
  final String date;
  final String time;

  const SelectedSlotCard({
    super.key,
    required this.userName,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(userName, color: AppColors.textPrimary),
        const SizedBox(height: 2),
        Row(
          children: [
            AppText.bold(
              "$date | $time",
              color: AppColors.primary),
          ]),
      ]);
  }
}
