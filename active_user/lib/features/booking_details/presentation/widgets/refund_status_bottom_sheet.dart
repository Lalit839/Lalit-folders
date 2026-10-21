import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RefundStatusBottomSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> refund;

  const RefundStatusBottomSheet({
    super.key,
    required this.booking,
    required this.refund,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> booking,
    required Map<String, dynamic> refund,
  }) {
    return showAppBottomSheet(
      context: context,
      title: 'My Refund',
      child: RefundStatusBottomSheet(booking: booking, refund: refund),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = refund['status']?.toString().toUpperCase() ?? 'PENDING';
    final amountPaise = num.tryParse('${refund['amountPaise']}') ?? 0;
    final amount = (amountPaise / 100).round();
    final bookingId = booking['publicCode']?.toString() ??
        booking['id']?.toString() ??
        'ACTIV00001';

    final slot = (booking['slot'] as Map<String, dynamic>?) ?? {};
    final facility = (slot['facility'] as Map<String, dynamic>?) ?? {};
    final venue = (facility['venue'] as Map<String, dynamic>?) ?? {};
    final venueName = venue['name']?.toString() ?? 'ACTIV Venue';
    final address = venue['cityCode']?.toString() ?? 'Indore';

    final bool isCompleted = status == 'COMPLETED' ||
        status == 'SUCCEEDED' ||
        status == 'CAPTURED' ||
        status == 'PROCESSED' ||
        status == 'REFUNDED';

    final bool isInitiated = status == 'INITIATED' || status == 'PROCESSING';

    final String statusLabel;
    final Color statusColor;
    if (status == 'FAILED') {
      statusLabel = 'Failed';
      statusColor = AppColors.errorRed;
    } else if (isCompleted) {
      statusLabel = 'Completed';
      statusColor = AppColors.primary;
    } else {
      statusLabel = 'Processing';
      statusColor = Colors.orange;
    }

    final String dateStr = refund['createdAt']?.toString() ?? '';
    final DateTime? createdAt = DateTime.tryParse(dateStr);
    final String formattedDate = createdAt != null
        ? DateFormat('d MMM yyyy').format(createdAt.toLocal())
        : DateFormat('d MMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blackColor2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            venueName,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          AppText.small(
                            address,
                            color: AppColors.grey99,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AppText.bold(
                        statusLabel,
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AppDivider(verticalPadding: 0),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.small(
                      'Booking ID',
                      color: AppColors.grey99,
                      fontSize: 14,
                    ),
                    AppText.medium(
                      bookingId,
                      color: AppColors.greyBorder,
                      fontSize: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.bold(
                      'Amount',
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    AppText.bold(
                      '₹$amount',
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Timeline
          _buildTimelineStep(
            title: 'Activ has initiated your refund',
            subtitle: null,
            statusText: isInitiated || isCompleted ? 'Completed' : 'Pending',
            dateText: isInitiated || isCompleted ? formattedDate : null,
            isCompleted: isInitiated || isCompleted,
            isLast: false,
          ),
          _buildTimelineStep(
            title: 'Bank UPI has processed your refund',
            subtitle: null,
            statusText: isCompleted ? 'Completed' : 'Pending',
            dateText: isCompleted ? formattedDate : null,
            isCompleted: isCompleted,
            isLast: false,
          ),
          _buildTimelineStep(
            title: 'Refund successfully credited to account.',
            subtitle: 'We are working on your refund. It may take some hours to credit the refund amount to your account.',
            statusText: isCompleted ? 'Completed' : 'Pending',
            dateText: isCompleted ? formattedDate : null,
            isCompleted: isCompleted,
            isLast: true,
          ),

          const SizedBox(height: 40),
          AppButton(
            title: 'Done',
            onTap: () => Navigator.pop(context),
            backgroundColor: Colors.transparent,
            textColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    required String statusText,
    String? dateText,
    required bool isCompleted,
    required bool isLast,
  }) {
    final dotColor = isCompleted ? AppColors.primary : AppColors.grey85;
    final statusColor = statusText == 'Pending' ? Colors.orange : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Line and Dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: AppColors.lightGreyBorder,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Right side: Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.medium(
                    title,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    maxLines: 2,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    AppText.small(
                      subtitle,
                      color: AppColors.grey85,
                      fontSize: 12,
                      maxLines: 3,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.medium(
                        statusText,
                        color: statusColor,
                        fontSize: 12,
                      ),
                      if (dateText != null)
                        AppText.small(
                          dateText,
                          color: AppColors.grey85,
                          fontSize: 12,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
