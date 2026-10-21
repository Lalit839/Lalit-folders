import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/inputs/app_input_field.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';

Future<String?> showAppSelectionBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  String initialSelection = '',
  String otherOptionText = 'Others',
}) {
  return showAppBottomSheet<String>(
    context: context,
    title: title,
    child: _AppSelectionBottomSheetContent(
      options: options,
      initialSelection: initialSelection,
      otherOptionText: otherOptionText,
    ),
  );
}

class _AppSelectionBottomSheetContent extends StatefulWidget {
  final List<String> options;
  final String initialSelection;
  final String otherOptionText;

  const _AppSelectionBottomSheetContent({
    required this.options,
    required this.initialSelection,
    required this.otherOptionText,
  });

  @override
  State<_AppSelectionBottomSheetContent> createState() =>
      _AppSelectionBottomSheetContentState();
}

class _AppSelectionBottomSheetContentState
    extends State<_AppSelectionBottomSheetContent> {
  String _selectedOption = '';
  final TextEditingController _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialSelection;
    if (!widget.options.contains(_selectedOption) &&
        _selectedOption.isNotEmpty) {
      _otherController.text = _selectedOption;
      _selectedOption = widget.otherOptionText;
    }
    _otherController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.options.map((option) {
            final isSelected = _selectedOption == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOption = option;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.yellowDark
                      : AppColors.blackColor2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.medium(
                      option,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    AppSvg(
                      isSelected
                          ? AppAssets.radioButton
                          : AppAssets.radioButton2,
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedOption == widget.otherOptionText) ...[
            AppInpuField(
              controller: _otherController,
              hintText: 'Please mention here...',
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 12),
          AppButton(
            title: 'Continue',
            isDisabled:
                _selectedOption == widget.otherOptionText &&
                _otherController.text.trim().isEmpty,
            onTap:
                (_selectedOption == widget.otherOptionText &&
                    _otherController.text.trim().isEmpty)
                ? null
                : () {
                    if (_selectedOption == widget.otherOptionText) {
                      Navigator.pop(context, _otherController.text.trim());
                    } else {
                      Navigator.pop(context, _selectedOption);
                    }
                  },
            backgroundColor: AppColors.blackColor2,
            textColor: AppColors.primary,
            showArrow: true,
          ),
        ],
      ),
    );
  }
}
