import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:intl/intl.dart';

class SelectWeekBottomSheet extends StatefulWidget {
  final DateTime initialDate;

  const SelectWeekBottomSheet({super.key, required this.initialDate});

  static Future<DateTime?> show(BuildContext context, {required DateTime initialDate}) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.blackColor2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SelectWeekBottomSheet(initialDate: initialDate),
    );
  }

  @override
  State<SelectWeekBottomSheet> createState() => _SelectWeekBottomSheetState();
}

class _SelectWeekBottomSheetState extends State<SelectWeekBottomSheet> {
  late DateTime _selectedDate;
  late List<DateTime> _weekStarts;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _weekStarts = _generateWeeks(widget.initialDate);
  }

  List<DateTime> _generateWeeks(DateTime date) {
    // Generate 4 weeks around the current date's month
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    
    // Find the monday before or on the first day of the month
    DateTime currentWeekStart = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    List<DateTime> weeks = [];
    for (int i = 0; i < 4; i++) {
      weeks.add(currentWeekStart);
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }
    return weeks;
  }

  String _formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${DateFormat('dd').format(start)} - ${DateFormat('dd MMMM yyyy').format(end)}';
    }
    return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
  }

  bool _isSameWeek(DateTime d1, DateTime d2) {
    final w1 = d1.subtract(Duration(days: d1.weekday - 1));
    final w2 = d2.subtract(Duration(days: d2.weekday - 1));
    return w1.year == w2.year && w1.month == w2.month && w1.day == w2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bold('Select Week Range', color: AppColors.textPrimary, fontSize: 16),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.grey99),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._weekStarts.asMap().entries.map((entry) {
            final idx = entry.key;
            final weekStart = entry.value;
            final isSelected = _isSameWeek(weekStart, _selectedDate);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = weekStart;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            'Week ${String.fromCharCode('0'.codeUnitAt(0) + idx + 1)}',
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          const SizedBox(height: 4),
                          AppText.small(
                            _formatWeekRange(weekStart),
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.grey99,
                            fontSize: 12,
                          ),
                        ],
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.grey99,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _selectedDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: AppText.bold('Apply', color: AppColors.black, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
