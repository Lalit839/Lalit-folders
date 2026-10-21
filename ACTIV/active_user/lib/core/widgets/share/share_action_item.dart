import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class ShareActionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const ShareActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blackColor2,
              shape: BoxShape.circle,
              // border: Border.all(color: AppColors.lightGreyBorder, width: 1)
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          AppText(
            label,
            color: AppColors.textPrimary,
            textAlign: TextAlign.center),
        ]));
  }
}
