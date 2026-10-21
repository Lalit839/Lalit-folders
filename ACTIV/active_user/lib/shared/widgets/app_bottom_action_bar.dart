import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class AppBottomActionBar extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const AppBottomActionBar({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.black,
    this.borderColor = AppColors.lightGreyBorder,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  factory AppBottomActionBar.fullWidthAction({
    Key? key,
    required String title,
    required VoidCallback? onTap,
    Color backgroundColor = AppColors.black,
    Color borderColor = AppColors.lightGreyBorder,
  }) {
    return AppBottomActionBar(
      key: key,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.bold(title, color: AppColors.primary, fontSize: 20),
              const SizedBox(width: 6),
              AppSvg(AppAssets.thickArrowRight, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(child: child),
    );
  }
}
