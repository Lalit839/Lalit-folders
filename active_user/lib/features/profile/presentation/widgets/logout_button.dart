import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: AppColors.lightGreyBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvg(
              AppAssets.logout,
              width: 24,
              height: 24,
              color: AppColors.errorRed),
            const SizedBox(width: 8),
            AppText.bold(
              'Logout',
              color: AppColors.greyBorder),
          ])));
  }
}
