import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class BookingTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const BookingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          // "Upcoming" Tab Button
          _TabButton(
            label: 'Upcoming',
            isSelected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),

          // "Completed" Tab Button
          _TabButton(
            label: 'Completed',
            isSelected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),

          // "Cancelled" Tab Button
          _TabButton(
            label: 'Cancelled',
            isSelected: selectedIndex == 2,
            onTap: () => onTabChanged(2),
          ),
        ],
      ),
    );
  }
}

// Reusable tab item button component
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors
                      .yellowDark // Color(0xFF242B0D)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: AppText.small(
            label,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
