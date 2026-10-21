import 'package:activ_user_app/core/widgets/image/app_svg_network.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class SportFilterList extends StatelessWidget {
  final List<Map<String, dynamic>> sports;
  final int selectedIndex;
  final ValueChanged<int> onSportSelected;

  const SportFilterList({
    super.key,
    required this.sports,
    required this.selectedIndex,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: sports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final sportName = sports[index]['name'] as String;
          final iconPath = sports[index]['icon'] as String?;
          final iconUrl = sports[index]['iconUrl'] as String? ?? '';

          return GestureDetector(
            onTap: () => onSportSelected(index),
            child: AppGradientContainer(
              isSelected: isSelected,
              borderRadius: 42,
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconUrl.isNotEmpty || iconPath != null) ...[
                    if (iconUrl.isNotEmpty)
                      AppSvgNetwork(iconUrl, height: 24, width: 24, fallbackAsset: iconPath ?? 'assets/images/turf.jpg')
                    else if ((iconPath ?? '').endsWith('.svg'))
                      AppSvg(iconPath!, height: 24, width: 24)
                    else if (iconPath != null)
                      Image.asset(iconPath, height: 24, width: 24),
                    const SizedBox(width: 6),
                  ],
                  isSelected
                      ? AppText.bold(
                          sportName,
                          color: AppColors.yellowColorLight,
                          fontSize: 16,
                        )
                      : AppText.medium(sportName, color: AppColors.greyBorder),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
