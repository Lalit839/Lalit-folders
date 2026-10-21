import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';

class PlayerCountSelector extends StatelessWidget {
  final int selectedCount;
  final ValueChanged<int> onCountSelected;

  const PlayerCountSelector({
    super.key,
    required this.selectedCount,
    required this.onCountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final counts = List.generate(30, (index) => index + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'How many players will join ?'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: counts.map((count) {
              final isSelected = selectedCount == count;
              final label = count.toString().padLeft(2, '0');

              return GestureDetector(
                onTap: () => onCountSelected(count),
                child: Container(
                  width: 58,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: isSelected
                      ? null
                      : const BoxDecoration(
                          color: AppColors.blackColor2,
                          shape: BoxShape.circle,
                        ),
                  child: AppGradientContainer(
                    isSelected: isSelected,
                    borderRadius: 48,
                    backgroundColor: AppColors.background,
                    child: Align(
                      alignment: Alignment.center,
                      child: AppText.medium(
                        label,
                        color: isSelected
                            ? AppColors.yellowColorLight
                            : AppColors.textPrimary,
                      ),
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
