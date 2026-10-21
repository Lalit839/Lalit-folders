import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 4,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
    widget.focusNode.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    widget.focusNode.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpText = widget.controller.text;

    return Stack(
      children: [
        // Hidden text field for keyboard capture
        Opacity(
          opacity: 0,
          child: SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),

        // OTP Boxes Row
        GestureDetector(
          onTap: () {
            widget.focusNode.requestFocus();
          },
          child: Row(
            spacing: 20,
            children: List.generate(widget.length, (index) {
              final digit = otpText.length > index ? otpText[index] : '';
              final isFocused =
                  widget.focusNode.hasFocus &&
                  (otpText.length == index ||
                      (otpText.length == widget.length &&
                          index == widget.length - 1));

              return Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFocused ? AppColors.primary : AppColors.white,
                    width: 1,
                  ),
                ),
                child: Text(
                  digit,
                  style: const TextStyle(fontSize: 14, color: AppColors.white),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
