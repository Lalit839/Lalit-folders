import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';

Future<void> showSuccessBottomSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  String? topPillText,
  required String primaryButtonText,
  required VoidCallback onPrimaryButtonTap,
  required String secondaryButtonText,
  required VoidCallback onSecondaryButtonTap,
  bool isError = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .9),
    builder: (context) {
      return PopScope(
        canPop: false,
        child: _SuccessBottomSheetContent(
          title: title,
          subtitle: subtitle,
          topPillText: topPillText,
          primaryButtonText: primaryButtonText,
          onPrimaryButtonTap: onPrimaryButtonTap,
          secondaryButtonText: secondaryButtonText,
          onSecondaryButtonTap: onSecondaryButtonTap,
          isError: isError,
        ),
      );
    },
  );
}

class _SuccessBottomSheetContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? topPillText;
  final String primaryButtonText;
  final VoidCallback onPrimaryButtonTap;
  final String secondaryButtonText;
  final VoidCallback onSecondaryButtonTap;
  final bool isError;

  const _SuccessBottomSheetContent({
    required this.title,
    required this.subtitle,
    this.topPillText,
    required this.primaryButtonText,
    required this.onPrimaryButtonTap,
    required this.secondaryButtonText,
    required this.onSecondaryButtonTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppSvg(
                  isError ? AppAssets.error : AppAssets.success,
                  width: 200,
                  height: 200,
                ),
                // const SizedBox(height: 32),
                if (topPillText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isError ? AppColors.black : AppColors.yellowDark,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: AppText.bold(
                      topPillText!,
                      color: isError ? AppColors.errorRed : AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AppText.bold(
                  title,
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AppText.small(
                  subtitle,
                  color: AppColors.grey99,
                  fontSize: 18,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppButton(
                  title: primaryButtonText,
                  onTap: onPrimaryButtonTap,
                  backgroundColor: AppColors.blackColor2,
                  textColor: AppColors.primary,
                  showArrow: true,
                ),
                const SizedBox(height: 16),
                AppButton(
                  title: secondaryButtonText,
                  onTap: onSecondaryButtonTap,
                  backgroundColor: Colors.transparent,
                  textColor: AppColors.greyBorder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
