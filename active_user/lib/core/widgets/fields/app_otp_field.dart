import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class AppOtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String)? onCompleted;
  final int length;
  final bool hasError;

  const AppOtpField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onCompleted,
    this.length = 4,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Default (base) theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 24, color: AppColors.white),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(8), // Rounded rectangle
        border: Border.all(color: AppColors.lightGreyBorder),
      ),
    );

    // 2. Focused box theme (slightly larger)
    final focusedPinTheme = defaultPinTheme.copyWith(
      width: 60,
      height: 60,
      decoration: defaultPinTheme.decoration?.copyWith(
        borderRadius: BorderRadius.circular(8), // Rounded rectangle
        border: Border.all(color: AppColors.primary, width: 1.5),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
    );

    // 3. Submitted (filled) box theme
    final submittedPinTheme = defaultPinTheme.copyWith(
      textStyle: const TextStyle(fontSize: 24, color: AppColors.primary),
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.yellowDark,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
    );

    // 4. Following (upcoming empty) box theme
    final followingPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.blackColor2,
        border: Border.all(color: AppColors.lightGreyBorder),
      ),
    );

    // 5. Error box theme
    final errorPinTheme = defaultPinTheme.copyWith(
      textStyle: const TextStyle(fontSize: 24, color: AppColors.errorRed),
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.blackColor2,
        border: Border.all(color: AppColors.errorRed, width: 1),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      focusNode: focusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      followingPinTheme: followingPinTheme,
      errorPinTheme: errorPinTheme,
      forceErrorState: hasError,
      onCompleted: onCompleted,
      keyboardType: TextInputType.number,
      autofocus: true,
      showCursor: true,
      isCursorAnimationEnabled: true,
      separatorBuilder: (index) => const SizedBox(width: 24),
    );
  }
}
