import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/activ_calendar_empty_state.dart';

class ActivCalendarWeekView extends StatelessWidget {
  final DateTime weekStart;
  final List<Map<String, dynamic>> activities;
  final Color Function(String) getSportColor;
  final Widget Function(String, Color) getSportIcon;
  final VoidCallback onShare;

  const ActivCalendarWeekView({
    super.key,
    required this.weekStart,
    required this.activities,
    required this.getSportColor,
    required this.getSportIcon,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    // Generate 7 days
    final days = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    // Group activities by date
    final Map<String, List<Map<String, dynamic>>> activitiesByDate = {};
    for (var act in activities) {
      final startsAt = DateTime.tryParse('${act['startsAt']}');
      if (startsAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(startsAt.toLocal());
        activitiesByDate.putIfAbsent(dateKey, () => []).add(act);
      }
    }

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((date) {
                return Expanded(
                  child: Column(
                    children: [
                      AppText.medium(
                        DateFormat('dd').format(date),
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      AppText.small(
                        DateFormat('E').format(date),
                        color: AppColors.grey99,
                        fontSize: 12,
                      ),
                      const SizedBox(height: 8),
                      // Small yellow dot
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ActivCalendarEmptyState(onShare: onShare),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.map((date) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final dayActivities = activitiesByDate[dateKey] ?? [];

          return Expanded(
            child: Column(
              children: [
                // Header (Date & Day)
                AppText.medium(
                  DateFormat('dd').format(date),
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
                AppText.small(
                  DateFormat('E').format(date), // Sun, Mon, etc.
                  color: AppColors.grey99,
                  fontSize: 12,
                ),
                const SizedBox(height: 16),
                
                // Timeline
                SizedBox(
                  height: 300, // Fixed height for timeline grid
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Dashed line
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: _VerticalDashedLinePainter(),
                        ),
                      ),
                      
                      // Activities
                      if (dayActivities.isEmpty)
                        // Rest Day
                        Positioned(
                          top: 20, // Arbitrary position for Rest Day
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.center,
                            child: _buildActivityIconAndText(
                              'Rest Day', 
                              AppColors.errorRed, 
                              const AppSvg(AppAssets.calendarRestDay, color: AppColors.errorRed, height: 24, width: 24),
                            ),
                          ),
                        )
                      else
                        ...dayActivities.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final act = entry.value;
                          final slot = act['slot'] as Map<String, dynamic>? ?? {};
                          final facility = slot['facility'] as Map<String, dynamic>? ?? {};
                          final sportName = facility['name']?.toString() ?? 'Activity';
                          final color = getSportColor(sportName);
                          final icon = getSportIcon(sportName, color);
                          
                          // Spread out the activities vertically
                          final topOffset = 20.0 + (idx * 60.0);
                          
                          return Positioned(
                            top: topOffset,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.center,
                              child: _buildActivityIconAndText(sportName, color, icon),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityIconAndText(String label, Color color, Widget icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.background, // Match app background to mask the dashed line
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 4),
        AppText.bold(
          label,
          color: color,
          fontSize: 8,
        ),
      ],
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  const _VerticalDashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lightGreyBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startY = 0;
    final startX = size.width / 2;
    const dashHeight = 4.0;
    const dashSpace = 4.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
