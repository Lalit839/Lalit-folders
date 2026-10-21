import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final bool iconRight;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine background color
    final defaultBgColor = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? theme.primaryColor);

    // Determine foreground (text/icon) color
    final defaultFgColor =
        foregroundColor ??
        (isOutlined
            ? theme.primaryColor
            : (defaultBgColor == AppColors.primary
                  ? Colors.black
                  : Colors.white));

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(width ?? double.infinity, height),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isOutlined
              ? Colors.transparent
              : (isDark ? AppColors.surface : Colors.grey.shade300);
        }
        return defaultBgColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? Colors.white38 : Colors.black26;
        }
        return defaultFgColor;
      }),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (isOutlined) {
          final color = states.contains(WidgetState.disabled)
              ? (isDark ? AppColors.border : Colors.grey.shade300)
              : defaultFgColor;
          return BorderSide(color: color, width: 1.5);
        }
        return null;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                onPressed == null
                    ? (isDark ? Colors.white38 : Colors.black26)
                    : defaultFgColor,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !iconRight) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null && iconRight) ...[
                const SizedBox(width: 8),
                icon!,
              ],
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            ),
    );
  }
}
