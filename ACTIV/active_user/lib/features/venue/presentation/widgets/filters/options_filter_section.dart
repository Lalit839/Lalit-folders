import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/filter_chip_item.dart';

class OptionsFilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onSelected;

  const OptionsFilterSection({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SubSectionHeader(title: title)),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = option == selectedOption;
            return FilterChipItem(
              label: option,
              isSelected: isSelected,
              showClearIcon: true,
              onTap: () => onSelected(option),
              onClear: isSelected ? () => onSelected('') : null);
          }).toList()),
      ]);
  }
}
