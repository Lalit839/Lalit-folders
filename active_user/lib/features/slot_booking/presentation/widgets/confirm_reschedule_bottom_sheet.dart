import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';

class RescheduleSummary {
  final String date;
  final String court;
  final String time;
  final String venue;
  const RescheduleSummary({
    required this.date,
    required this.court,
    required this.time,
    required this.venue,
  });
}

Future<bool?> showConfirmRescheduleBottomSheet(
  BuildContext context, {
  required RescheduleSummary current,
  required RescheduleSummary neu,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    title: 'Confirm Reschedule',
    child: _ConfirmRescheduleContent(current: current, neu: neu),
  );
}

class _ConfirmRescheduleContent extends StatelessWidget {
  final RescheduleSummary current;
  final RescheduleSummary neu;
  const _ConfirmRescheduleContent({
    required this.current,
    required this.neu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Booking Card
          _buildBookingCard(
            title: 'Current Booking',
            titleColor: AppColors.textPrimary,
            backgroundColor: AppColors.blackColor2,
            venue: current.venue,
            date: current.date,
            court: current.court,
            time: current.time,
          ),
          const SizedBox(height: 16),
          // New Booking Card
          _buildBookingCard(
            title: 'New Booking',
            titleColor: AppColors.primary,
            backgroundColor: AppColors.yellowDark,
            venue: neu.venue,
            date: neu.date,
            court: neu.court,
            time: neu.time,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: 'Cancel',
                  onTap: () => Navigator.pop(context, false),
                  backgroundColor: Colors.transparent,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.lightGreyBorder,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  title: 'Confirm',
                  onTap: () => Navigator.pop(context, true),
                  backgroundColor: AppColors.blackColor2,
                  textColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String title,
    required Color titleColor,
    required Color backgroundColor,
    required String venue,
    required String date,
    required String court,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.medium(title, color: titleColor, fontSize: 16),
          const SizedBox(height: 16),
          _buildSvgRow(AppAssets.calendar, date),
          const SizedBox(height: 8),
          _buildSvgRow(AppAssets.turf, court),
          const SizedBox(height: 8),
          _buildSvgRow(AppAssets.time, time),
        ],
      ),
    );
  }

  Widget _buildSvgRow(String asset, String text) {
    return Row(
      children: [
        AppSvg(asset, width: 24, height: 24, color: AppColors.greyBorder),
        const SizedBox(width: 12),
        AppText.small(text, color: AppColors.textPrimary, fontSize: 16),
      ],
    );
  }
}
