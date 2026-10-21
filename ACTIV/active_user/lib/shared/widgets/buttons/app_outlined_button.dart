import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double borderRadius;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppOutlinedButton({
    super.key,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 56,
    this.borderRadius = 12,
    this.prefixIcon,
    this.suffixIcon,
  });

  static const Color _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading || onTap == null;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: disabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: disabled ? Colors.grey.shade700 : _primaryColor,
          ),
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: const TextStyle(fontSize: 18)),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: 8),
                    suffixIcon!,
                  ],
                ],
              ),
      ),
    );
  }
}
