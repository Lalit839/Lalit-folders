import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/filter_chip_item.dart';

class BookingActivitySelector extends StatelessWidget {
  final List<String> activities;
  final String? selectedActivity;
  final ValueChanged<String> onActivitySelected;

  const BookingActivitySelector({
    super.key,
    required this.activities,
    required this.selectedActivity,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'Activity Type'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: activities.map((activity) {
              final isSelected = selectedActivity == activity;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChipItem(
                  label: activity,
                  isSelected: isSelected,
                  showClearIcon: false,
                  onTap: () => onActivitySelected(activity),
                  prefixIcon: Image.asset(
                    iconForSport(activity),
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.sports,
                      size: 22,
                      color: isSelected
                          ? AppColors.yellowColorLight
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
