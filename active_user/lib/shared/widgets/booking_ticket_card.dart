import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum BookingTicketStatus { active, rescheduled, cancelled, completed }

class BookingTicketCard extends StatelessWidget {
  final BookingTicketStatus status;
  final String date;
  final String venueName;
  final String address;
  final String activity;
  final String slot;
  final List<String> courts;
  final String type;
  final String totalPlayers;
  final String amountPaid;
  final String bookingId;
  final String? venueAssistant;
  final String? phoneNo;
  final VoidCallback? onGetDirection;

  const BookingTicketCard({
    super.key,
    required this.status,
    required this.date,
    required this.venueName,
    required this.address,
    required this.activity,
    required this.slot,
    required this.courts,
    required this.type,
    required this.totalPlayers,
    required this.amountPaid,
    required this.bookingId,
    this.venueAssistant,
    this.phoneNo,
    this.onGetDirection,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = status == BookingTicketStatus.cancelled;

    final Color headerColor = isCancelled
        ? AppColors.grey85
        : AppColors.primary;
    final Color footerColor = isCancelled
        ? AppColors.grey70
        : AppColors.paleLime;
    final Color headerTextColor = isCancelled
        ? AppColors.white
        : AppColors.surface;
    final Color bodyColor = AppColors.textPrimary;
    const double radius = 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Card Part
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                  ),
                ),
                child: Row(
                  children: [
                    AppSvg(
                      AppAssets.calendar,
                      color: headerTextColor,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.bold(
                        date,
                        color: headerTextColor,
                        fontSize: 20,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Top Body
              Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,

                    child: AppSvg(
                      _getSportSvgPath(activity),
                      width: 90,
                      height: 90,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.medium(
                          'Venue Name',
                          color: AppColors.grey99,
                          fontSize: 14,
                        ),
                        AppText.bold(
                          venueName,
                          color: AppColors.black,
                          fontSize: 24,
                          maxLines: 3,
                        ),
                        AppText.small(
                          address,
                          color: AppColors.black,
                          fontSize: 16,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Middle Divider with Cutouts
        Container(
          color: bodyColor,
          child: Row(
            children: [
              // Left cutout
              Container(
                height: 32,
                width: 16,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              // Divider Line
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AppDivider(verticalPadding: 24),
                ),
              ),
              // Right cutout
              Container(
                height: 32,
                width: 16,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Card Part
        Container(
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(radius),
              bottomRight: Radius.circular(radius),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom Body (Details)
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 0,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details Row 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildDetailColumn('Activity', activity),
                        ),
                        Expanded(
                          child: _buildDetailColumn(
                            'Slot (${courts.length})',
                            slot,
                          ),
                        ),
                        Expanded(
                          child: _buildListDetailColumn(
                            'Court (${courts.length})',
                            courts,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Details Row 2
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailColumn('Type of', type)),
                        Expanded(
                          child: _buildDetailColumn(
                            'Total Players',
                            totalPlayers,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailColumn('Amount Paid', amountPaid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Assistant Info (if not cancelled and available)
              if (!isCancelled && venueAssistant != null && phoneNo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  color: const Color(0xFFE8E8E8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailColumn(
                          'Venue Assistant',
                          venueAssistant!,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailColumn('Phone No.', phoneNo!),
                      ),
                    ],
                  ),
                ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: footerColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.medium(
                            'Booking ID',
                            color: AppColors.grey99,
                            fontSize: 14,
                          ),
                          AppText.bold(
                            bookingId,
                            color: AppColors.surface,
                            fontSize: 18,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isCancelled)
                      OutlinedButton.icon(
                        onPressed: onGetDirection,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.yellowDark,
                          side: const BorderSide(color: AppColors.yellowDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: AppSvg(
                          AppAssets.directions,
                          width: 24,
                          height: 24,
                          color: AppColors.yellowDark,
                        ),
                        label: AppText.medium(
                          'Get Direction',
                          color: AppColors.surface,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium(
          label,
          color: AppColors.grey99,
          fontSize: 14,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        AppText.bold(
          value,
          color: AppColors.surface,
          fontSize: 18,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildListDetailColumn(String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium(
          label,
          color: AppColors.grey99,
          fontSize: 14,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        ...values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AppText.bold(
              value,
              color: AppColors.surface,
              fontSize: 18,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  String _getSportSvgPath(String activityName) {
    final activity = activityName.toLowerCase();

    if (activity.contains('football')) return AppAssets.svgFootball;
    if (activity.contains('cricket')) return AppAssets.svgCricket;
    if (activity.contains('basketball')) return AppAssets.svgBasketball;
    if (activity.contains('tennis') && !activity.contains('table')) {
      return AppAssets.svgTennis;
    }
    if (activity.contains('table tennis')) return AppAssets.svgTableTennis;
    if (activity.contains('badminton')) return AppAssets.svgBadminton;
    if (activity.contains('volleyball')) return AppAssets.svgVolleyball;
    if (activity.contains('pool') && !activity.contains('swimming')) {
      return AppAssets.svgPool;
    }
    if (activity.contains('swimming')) return AppAssets.svgPool1;
    if (activity.contains('gym')) return AppAssets.svgGym;
    if (activity.contains('yoga')) return AppAssets.svgYoga;
    if (activity.contains('adventure sports')) {
      return AppAssets.svgAdventureSports;
    }
    if (activity.contains('archery')) return AppAssets.svgArchery;
    if (activity.contains('bouldering')) return AppAssets.svgBouldering;
    if (activity.contains('bowling')) return AppAssets.svgBowling;
    if (activity.contains('boxing')) return AppAssets.svgBoxing;
    if (activity.contains('crossfit')) return AppAssets.svgCrossfit;
    if (activity.contains('dance')) return AppAssets.svgDance;
    if (activity.contains('equestrian')) return AppAssets.svgEquestrian;
    if (activity.contains('frisbee')) return AppAssets.svgFrisbee;
    if (activity.contains('hiit')) return AppAssets.svgHiit;
    if (activity.contains('hockey')) return AppAssets.svgHockey;
    if (activity.contains('marshal art') || activity.contains('martial')) {
      return AppAssets.svgMarshalArt;
    }
    if (activity.contains('mma')) return AppAssets.svgMma;
    if (activity.contains('padel')) return AppAssets.svgPadel;
    if (activity.contains('paintball')) return AppAssets.svgPaintball;
    if (activity.contains('pickleball')) return AppAssets.svgPickleball;
    if (activity.contains('pilates')) return AppAssets.svgPilates;
    if (activity.contains('rock climbing')) return AppAssets.svgRockClimbing;
    if (activity.contains('shooting')) return AppAssets.svgShooting;
    if (activity.contains('skating')) return AppAssets.svgSkating;
    if (activity.contains('squash')) return AppAssets.svgSquash;
    if (activity.contains('teqball')) return AppAssets.svgTeqball;
    if (activity.contains('trampoline')) return AppAssets.svgTrampoline;
    if (activity.contains('turf cricket')) return AppAssets.svgTurfCricket;

    return AppAssets.svgOther;
  }
}
