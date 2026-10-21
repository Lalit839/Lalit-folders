import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class ActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color color;

  const ActionTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 16,
    this.color = AppColors.greyBorder,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.small(label, fontSize: fontSize, color: color),
          const SizedBox(width: 4),
          AppSvg(AppAssets.thickArrowRight, width: 24, height: 24),
        ],
      ),
    );
  }
}
