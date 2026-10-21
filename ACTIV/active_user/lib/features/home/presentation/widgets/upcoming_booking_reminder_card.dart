import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class UpcomingBookingReminderCard extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onViewDetails;
  final String venueName;
  final DateTime startsAt;

  const UpcomingBookingReminderCard({
    super.key,
    required this.onClose,
    required this.onViewDetails,
    required this.venueName,
    required this.startsAt,
  });

  String _timeLabel(DateTime startsAt) {
    final local = startsAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    final time = DateFormat('h:mm a').format(local);
    if (diff == 0) return 'Today $time';
    if (diff == -1) return 'Tomorrow $time';
    return '${DateFormat('EEE, d MMM').format(local)}, $time';
  }

  String _countdownLabel(DateTime startsAt) {
    final delta = startsAt.toLocal().difference(DateTime.now());
    final minutes = delta.inMinutes.clamp(0, 1 << 31);
    if (minutes < 60) return '$minutes m';
    return '${minutes ~/ 60} h ${minutes % 60} m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.yellowDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  top: 24.0,
                  right: 8.0,
                  bottom: 12.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Image.asset(AppAssets.football, width: 80, height: 80),
                    const SizedBox(width: 8),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            'Upcoming Booking',
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                          const SizedBox(height: 2),
                          AppText.bold(
                            venueName,
                            color: AppColors.white,
                            fontSize: 20,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          AppText.small(
                            _timeLabel(startsAt),
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  bottom: 24.0,
                ),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.blackColor2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14.0),
                          child: Row(
                            children: [
                              const AppSvg(
                                AppAssets.time,
                                color: AppColors.primary,
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: AppText.small(
                                        'Starts in ',
                                        color: AppColors.white,
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Flexible(
                                      child: AppText.bold(
                                        _countdownLabel(startsAt),
                                        color: AppColors.white,
                                        fontSize: 16,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onViewDetails,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: AppText.bold(
                            'View Details',
                            color: AppColors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Close button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                color: Colors.transparent, // increases tap target area
                child: const AppSvg(
                  AppAssets.cross,
                  color: AppColors.greyBorder,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
