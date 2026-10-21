import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class ProfileMenuItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          children: [
            AppSvg(iconPath, width: 24, height: 24, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(title, color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
