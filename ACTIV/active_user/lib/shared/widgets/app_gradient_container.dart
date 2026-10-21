import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class AppGradientContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;
  final Color backgroundColor;

  const AppGradientContainer({
    super.key,
    required this.child,
    this.isSelected = true,
    this.borderRadius = 42,
    this.padding,
    this.borderWidth = 1.0,
    this.backgroundColor = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isSelected ? EdgeInsets.all(borderWidth) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.transparentGrey, AppColors.yellowColor],
                stops: [0.3172, 1.0], // To match the 31.72% from your CSS
              )
            : null),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? null : Colors.transparent,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundColor, AppColors.yellowDark],
                  stops: const [0.0, 1.0])
              : null,
          borderRadius: BorderRadius.circular(
            // Inner radius usually should be slightly smaller than outer by the border width,
            // but for large radii it's fine to keep them same or close.
            isSelected ? borderRadius - borderWidth : borderRadius),
          border: isSelected
              ? null
              // If not selected, we still might want a transparent border to keep dimensions consistent
              : Border.all(color: Colors.transparent, width: borderWidth)),
        child: child));
  }
}
