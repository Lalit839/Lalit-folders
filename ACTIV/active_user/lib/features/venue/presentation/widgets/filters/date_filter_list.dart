import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class DateFilterList extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int dayCount;

  const DateFilterList({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dayCount = 30, // 30 days default
  });

  @override
  State<DateFilterList> createState() => _DateFilterListState();
}

class _DateFilterListState extends State<DateFilterList> {
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    final today = DateUtils.dateOnly(DateTime.now());
    _dates = List.generate(
      widget.dayCount,
      (index) => DateUtils.addDaysToDate(today, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dates.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected =
              widget.selectedDate != null &&
              DateUtils.isSameDay(date, widget.selectedDate);

          final isFirstOfMonth =
              index == 0 || date.month != _dates[index - 1].month;
          final monthString = DateFormat('MMM').format(date).toUpperCase();

          final nextIsFirstOfMonth =
              index < _dates.length - 1 &&
              _dates[index + 1].month != date.month;

          final showDivider =
              !isSelected &&
              index < _dates.length - 1 &&
              (widget.selectedDate == null ||
                  !DateUtils.isSameDay(
                    _dates[index + 1],
                    widget.selectedDate,
                  )) &&
              !nextIsFirstOfMonth;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirstOfMonth)
                Padding(
                  padding: EdgeInsets.only(
                    // left: index == 0 ? 0 : 16.0,
                    right: 12.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 16,
                    ),
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyBorder,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: AppText.medium(
                        monthString,
                        color: AppColors.greyBorder,

                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

              GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  width: 56,
                  height: 72,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.medium(
                        DateFormat('dd').format(date),
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.greyBorder,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 2),
                      AppText.medium(
                        DateFormat('EEE').format(date),
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.greyBorder,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ),

              if (showDivider)
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.lightGreyBorder,
                )
              else if (index < _dates.length - 1 && !nextIsFirstOfMonth)
                const SizedBox(width: 33), // 16 + 1 + 16
            ],
          );
        },
      ),
    );
  }
}
