import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/routes/app_routes.dart';

Future<void> showDeleteAccountBottomSheet(BuildContext context) {
  return showConfirmationBottomSheet(
    context: context,
    iconPath: AppAssets.deleteIcon,
    title: 'Delete Account',
    description:
        'All data associated with your account including your profile, bookings, photos, and reviews will be permanently deleted after 30 days. Once your account is permanently deleted, this action cannot be reversed, and your data cannot be recovered.',
    primaryButtonTitle: 'Delete Account',
    primaryButtonColor: AppColors.errorRed,
    onPrimaryButtonTap: () {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(AppRoutes.deleteAccount);
    },
  );
}
