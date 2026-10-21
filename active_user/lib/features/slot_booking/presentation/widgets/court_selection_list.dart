import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/slot_booking/data/models/booking_models.dart';

class CourtSelectionList extends StatelessWidget {
  final List<CourtModel> availableCourts;
  final List<String> selectedCourtIds;
  final ValueChanged<String> onCourtSelected;

  const CourtSelectionList({
    super.key,
    required this.availableCourts,
    required this.selectedCourtIds,
    required this.onCourtSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableCourts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),

        SubSectionHeader(title: 'Court Available : 0${availableCourts.length}'),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableCourts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final court = availableCourts[index];
            final isSelected = selectedCourtIds.contains(court.id);

            return GestureDetector(
              onTap: () => onCourtSelected(court.id),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.yellowDark
                      : AppColors.blackColor2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.transparent,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 3, right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey99,
                        ),
                      ),
                      child: isSelected
                          ? const Center(child: AppSvg(AppAssets.rightTick))
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.medium(
                            court.turfType.isEmpty
                                ? court.name
                                : '${court.name} - ${court.turfType}',
                            color: AppColors.textPrimary,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            '${court.availableQuantity} spot${court.availableQuantity > 1 ? 's' : ''}  |  ${court.venueType}',
                            color: AppColors.grey99,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          AppText.medium(
                            '₹${court.price.toInt()}',
                            color: AppColors.yellowColorLight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}