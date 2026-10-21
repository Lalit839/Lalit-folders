import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';

Future<void> showReviewSuccessBottomSheet({
  required BuildContext context,
  required VoidCallback onDone,
  String title = 'Review Submitted!',
  String description =
      'Thanks for sharing your experience.\nYour feedback helps us improve.',
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .9),
    builder: (context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: _ReviewSuccessBottomSheetContent(
            onDone: onDone,
            title: title,
            description: description,
          ),
        ),
      );
    },
  );
}

class _ReviewSuccessBottomSheetContent extends StatelessWidget {
  final VoidCallback onDone;
  final String title;
  final String description;

  const _ReviewSuccessBottomSheetContent({
    required this.onDone,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppSvg(AppAssets.success, width: 140, height: 140),
              const SizedBox(height: 24),
              AppText.bold(
                title,
                color: AppColors.textPrimary,
                fontSize: 24,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppText.small(
                description,
                color: AppColors.grey99,
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppButton(
                title: 'Done',
                onTap: onDone,
                backgroundColor: AppColors.blackColor2,
                textColor: AppColors.primary,
                showArrow: false,
              ),
            ],
          ),
    );
  }
}
