import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/slot_booking/presentation/controllers/book_slot_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';

class TimeSlotGrid extends ConsumerWidget {
  final List<DateTime> availableSlots;
  final List<DateTime> allSlots;
  final DateTime? selectedSlot;
  final int durationMinutes;
  final int? requiredPricePaise;
  final ValueChanged<DateTime> onSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.availableSlots,
    required this.allSlots,
    required this.selectedSlot,
    required this.durationMinutes,
    this.requiredPricePaise,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (allSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No slots available.',
          style: TextStyle(color: AppColors.grey99),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allSlots.length,
      itemBuilder: (context, index) {
        final slot = allSlots[index];
        final slotEnd = slot.add(Duration(minutes: durationMinutes));

        final isAvailable = availableSlots.contains(slot);
        final isSelected = selectedSlot == slot;
        final timeString =
            '${DateFormat('h').format(slot)} - ${DateFormat('h a').format(slotEnd)}';

        // Fetch real court availability for this slot
        int courtsAvail = ref
            .read(bookSlotControllerProvider.notifier)
            .getAvailableCourtsCountForSlot(
              slot,
              requiredPricePaise: requiredPricePaise,
            );
        String subText = '';

        if (courtsAvail > 0) {
          subText = '$courtsAvail Court${courtsAvail > 1 ? 's' : ''}';
        } else {
          subText = 'Not available';
        }

        Color borderColor = Colors.transparent;
        Color textColor = AppColors.textPrimary;
        Color subTextColor = AppColors.grey99.withValues(alpha: 0.5);

        if (isSelected) {
          borderColor = AppColors.primary;
          textColor = AppColors.textPrimary;
          subTextColor = AppColors.primary;
        } else if (isAvailable) {
          textColor = AppColors.textPrimary;
          subTextColor = AppColors.primary;
        }

        return GestureDetector(
          onTap: isAvailable ? () => onSlotSelected(slot) : null,
          child: Container(
            decoration: isSelected
                ? null
                : BoxDecoration(
                    color: AppColors.blackColor2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
            child: AppGradientContainer(
              isSelected: isSelected,
              borderRadius: 12,
              backgroundColor: AppColors.background,
              child: Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.bold(
                        timeString,
                        fontSize: 14, // reduced from 16
                        color: isSelected
                            ? AppColors.yellowColorLight
                            : textColor,
                      ),
                      const SizedBox(height: 1),

                      AppText.medium(
                        subText,
                        fontSize: 9, // reduced from 10
                        color: isSelected
                            ? AppColors.yellowColorLight
                            : subTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

