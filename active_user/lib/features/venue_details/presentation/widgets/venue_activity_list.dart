import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_activity_chip.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class VenueActivityList extends StatelessWidget {
  final List<VenueActivity> activities;
  final String? selectedActivityId;
  final ValueChanged<String> onActivitySelected;

  const VenueActivityList({
    super.key,
    required this.activities,
    required this.selectedActivityId,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    final selectedActivity = activities.firstWhere(
      (a) => a.id == selectedActivityId,
      orElse: () => activities.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'Available Activities'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: activities.map((activity) {
              final isSelected = activity.id == selectedActivityId;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: VenueActivityChip(
                  activity: activity,
                  isSelected: isSelected,
                  onTap: () => onActivitySelected(activity.id),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedActivity.variations.map((variation) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blackColor2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppText.medium(
                variation,
                color: AppColors.grey99,
                fontSize: 14,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
