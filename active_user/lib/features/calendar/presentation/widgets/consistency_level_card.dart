import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class ConsistencyLevelCard extends StatelessWidget {
  final bool isWeekView;
  final int activeDaysCount;
  final int? dayActivityCount;
  final VoidCallback onShare;

  const ConsistencyLevelCard({
    super.key,
    required this.isWeekView,
    required this.activeDaysCount,
    this.dayActivityCount,
    required this.onShare,
  });

  String get _streakLabel {
    final count = isWeekView ? activeDaysCount : (dayActivityCount ?? 0);
    if (count >= 7) return 'Perfect Week';
    if (count >= 5) return 'On fire';
    if (count >= 3) return 'Good streak';
    if (count >= 1) return 'Getting started';
    return 'Resting';
  }

  @override
  Widget build(BuildContext context) {
    final filledCount =
        (isWeekView ? activeDaysCount : (dayActivityCount ?? 0)).clamp(0, 7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.small(
                      'Consistency Level',
                      color: AppColors.grey99,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 4),
                    AppText.bold(
                      isWeekView
                          ? '$activeDaysCount Out of 7 Days'
                          : '${dayActivityCount ?? 0} Activities Today',
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.errorRed,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      AppText.medium(
                        _streakLabel,
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashes reflecting real activity count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomPaint(
              painter: _DashedLinePainter(filledCount: filledCount),
              child: const SizedBox(height: 24, width: double.infinity),
            ),
          ),

          // Share Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.yellowDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.ios_share,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    AppText.bold(
                      'Share Your Activity',
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final int filledCount;

  const _DashedLinePainter({required this.filledCount});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 24.0;
    const dashSpace = 10.0;
    const gapBeforeFirst = 8.0;
    final totalDashes = 7;
    final paint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    double startX = gapBeforeFirst;
    for (int i = 0; i < totalDashes; i++) {
      paint.color = i < filledCount
          ? AppColors.primary
          : AppColors.grey85.withValues(alpha: 0.3);
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.filledCount != filledCount;
}