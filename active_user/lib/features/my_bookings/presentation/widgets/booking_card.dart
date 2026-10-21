import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/features/my_bookings/presentation/widgets/booking_status_chip.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class BookingCard extends StatelessWidget {
  final String title;
  final String sport;
  final String location;
  final String date;
  final String time;
  final String? status;
  final String? bookingId;

  const BookingCard({
    super.key,
    required this.title,
    required this.sport,
    required this.location,
    required this.date,
    required this.time,
    this.status,
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card Container
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.bookingDetails,
              arguments: {'status': status, 'bookingId': bookingId},
            );
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: (status != null && status!.isNotEmpty) ? 20 : 8,
              bottom: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.blackColor2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Left Details Section (Title, Sport & Location)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.bold(
                        title,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText.small(
                        '$sport | $location',
                        color: AppColors.grey99,
                        fontSize: 14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Vertical Divider
                Container(
                  height: 24,
                  width: 1,
                  color: AppColors.lightGreyBorder,
                ),
                const SizedBox(width: 16),

                // Right Date/Time Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.bold(
                      date,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 4),
                    AppText.small(
                      time,
                      color: AppColors.grey99,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (status != null && status!.isNotEmpty)
          Positioned(
            top: 0,
            left: 16,
            child: BookingStatusChip(status: status!),
          ),
      ],
    );
  }
}
