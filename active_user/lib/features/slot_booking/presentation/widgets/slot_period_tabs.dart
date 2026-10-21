import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class SlotPeriodTabs extends StatelessWidget {
  final List<String> periods = const ['Morning', 'Noon', 'Evening', 'Night'];
  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  const SlotPeriodTabs({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          // Continuous unselected border line
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 2, color: AppColors.blackColor2),
          ),
          // Tabs
          Row(
            children: periods.map((period) {
              final isSelected = selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 0),
                child: GestureDetector(
                  onTap: () => onPeriodSelected(period),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AppText.bold(
                      period,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
