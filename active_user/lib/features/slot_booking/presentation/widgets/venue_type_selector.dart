import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/filter_chip_item.dart';

class VenueTypeSelector extends StatelessWidget {
  final List<String> venueTypes;
  final String? selectedVenueType;
  final ValueChanged<String> onVenueSelected;

  final List<String> turfTypes;
  final String? selectedTurfType;
  final ValueChanged<String> onTurfSelected;

  const VenueTypeSelector({
    super.key,
    required this.venueTypes,
    required this.selectedVenueType,
    required this.onVenueSelected,
    required this.turfTypes,
    required this.selectedTurfType,
    required this.onTurfSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'Venue Type'),
        const SizedBox(height: 16),
        // Venue Types (In-door, Out-door)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: venueTypes.map((venue) {
            final isSelected = selectedVenueType == venue;
            return FilterChipItem(
              label: venue,
              isSelected: isSelected,
              showClearIcon: false,
              onTap: () => onVenueSelected(venue));
          }).toList()),
        const SizedBox(height: 16),
        // Turf Types (6 vs 6 Turf)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: turfTypes.map((turf) {
            final isSelected = selectedTurfType == turf;
            return FilterChipItem(
              label: turf,
              isSelected: isSelected,
              showClearIcon: false,
              onTap: () => onTurfSelected(turf));
          }).toList()),
      ]);
  }
}
