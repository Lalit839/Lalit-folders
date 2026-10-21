import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class BookingDurationSelector extends StatelessWidget {
  final List<int> durations;
  final int selectedDuration;
  final ValueChanged<int> onDurationSelected;

  const BookingDurationSelector({
    super.key,
    required this.durations,
    required this.selectedDuration,
    required this.onDurationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final label = selectedDuration == 60
        ? '1 hr'
        : selectedDuration == 90
        ? '1.5 hrs'
        : '${selectedDuration ~/ 60} hrs';

    final currentIndex = durations.indexOf(selectedDuration);
    final canDecrement = currentIndex > 0;
    final canIncrement =
        currentIndex >= 0 && currentIndex < durations.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bold('Select Slot', color: AppColors.primary),

        // Duration "Dropdown" Style Stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGreyBorder, width: 1),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: canDecrement
                    ? () => onDurationSelected(durations[currentIndex - 1])
                    : null,
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: canDecrement ? AppColors.black : AppColors.greyBorder,
                ),
              ),
              const SizedBox(width: 12),

              AppText.bold(label, fontSize: 16, color: AppColors.black),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: canIncrement
                    ? () => onDurationSelected(durations[currentIndex + 1])
                    : null,
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: canIncrement ? AppColors.black : AppColors.greyBorder,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
