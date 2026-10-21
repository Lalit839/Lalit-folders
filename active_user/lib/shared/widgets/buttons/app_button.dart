import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double borderRadius;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showArrow;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 56,
    this.borderRadius = 48,
    this.prefixIcon,
    this.suffixIcon,
    this.showArrow = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.fontSize,
  });

  static const Color _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading || onTap == null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: disabled
              ? AppColors.lightGreyBorder
              : (backgroundColor ?? _primaryColor),
          foregroundColor: textColor ?? Colors.black,
          disabledBackgroundColor: AppColors.lightGreyBorder,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor ?? Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize ?? 18,
                      color: disabled
                          ? AppColors.grey99
                          : (textColor ?? Colors.black),
                    ),
                  ),
                  if (suffixIcon != null || showArrow) ...[
                    const SizedBox(width: 8),
                    suffixIcon ??
                        AppSvg(
                          AppAssets.thickArrowRight,
                          color: disabled
                              ? AppColors.grey99
                              : (textColor ?? Colors.black),
                          width: 24,
                          height: 24,
                        ),
                  ],
                ],
              ),
      ),
    );
  }
}
