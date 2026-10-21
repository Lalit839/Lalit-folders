import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';

class ActivCalendarDayView extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final Color Function(String) getSportColor;
  final Widget Function(String, Color) getSportIcon;

  const ActivCalendarDayView({
    super.key,
    required this.activities,
    required this.getSportColor,
    required this.getSportIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: AppText.medium(
            'No activities scheduled for this day.',
            color: AppColors.grey99,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AppText.bold(
            '${activities.length} Activities Completed',
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...activities.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          final slot = item['slot'] as Map<String, dynamic>? ?? {};
          final facility = slot['facility'] as Map<String, dynamic>? ?? {};
          final venue = facility['venue'] as Map<String, dynamic>? ?? {};
          
          final sportName = facility['name']?.toString() ?? 'Activity';
          final venueName = venue['name']?.toString() ?? 'ACTIV Venue';
          
          final startsAt = DateTime.tryParse('${item['startsAt']}')?.toLocal();
          final endsAt = DateTime.tryParse('${slot['endsAt']}')?.toLocal();
          final timeStr = startsAt != null && endsAt != null
              ? '${DateFormat('h').format(startsAt)} - ${DateFormat('h a').format(endsAt)}'.toLowerCase()
              : '';

          final sportColor = getSportColor(sportName);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    getSportIcon(sportName, sportColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            sportName,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          const SizedBox(height: 2),
                          AppText.small(
                            venueName,
                            color: AppColors.grey99,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                    AppText.medium(
                      timeStr,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
              if (index < activities.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppDivider(verticalPadding: 0),
                ),
            ],
          );
        }),
      ],
    );
  }
}
