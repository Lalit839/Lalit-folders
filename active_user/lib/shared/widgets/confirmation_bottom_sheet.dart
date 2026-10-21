import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

Future<void> showConfirmationBottomSheet({
  required BuildContext context,
  required String iconPath,
  Color? iconColor,
  required String title,
  required String description,
  required String primaryButtonTitle,
  required Color primaryButtonColor,
  required VoidCallback onPrimaryButtonTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.lightGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppSvg(iconPath, height: 24, width: 24, color: iconColor),
                  ),
                ),
                const SizedBox(height: 8),
                AppText.bold(
                  title,
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 10),
                AppText.small(
                  description,
                  fontSize: 18,
                  color: AppColors.grey99,
                  textAlign: TextAlign.center,
                  height: 1.5,
                ),
                const SizedBox(height: 40),
                AppButton(
                  title: primaryButtonTitle,
                  backgroundColor: primaryButtonColor,
                  textColor: AppColors.textPrimary,
                  onTap: onPrimaryButtonTap,
                ),
                const SizedBox(height: 16),
                AppButton(
                  title: 'Cancel',
                  backgroundColor: Colors.transparent,
                  borderColor: AppColors.lightGreyBorder,
                  textColor: AppColors.textPrimary,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
