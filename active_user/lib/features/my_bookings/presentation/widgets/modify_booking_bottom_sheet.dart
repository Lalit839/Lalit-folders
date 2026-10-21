import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:flutter/material.dart';

class ModifyBookingBottomSheet extends StatefulWidget {
  final bool isRescheduled;
  final String? bookingId;
  const ModifyBookingBottomSheet({
    super.key,
    this.isRescheduled = false,
    this.bookingId,
  });

  static Future<void> show(
    BuildContext context, {
    bool isRescheduled = false,
    String? bookingId,
  }) {
    return showAppBottomSheet(
      context: context,
      title: 'Select an Option',
      child: ModifyBookingBottomSheet(
        isRescheduled: isRescheduled,
        bookingId: bookingId,
      ),
    );
  }

  @override
  State<ModifyBookingBottomSheet> createState() =>
      _ModifyBookingBottomSheetState();
}

class _ModifyBookingBottomSheetState extends State<ModifyBookingBottomSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.isRescheduled ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            index: 0,
            title: 'Reschedule Booking',
            isEnabled: !widget.isRescheduled,
            disabledMessage: 'You can only reschedule a booking once',
          ),
          const SizedBox(height: 12),
          _buildOption(index: 1, title: 'Cancel My Booking', isEnabled: true),
          const SizedBox(height: 32),
          AppButton(
            title: 'Continue',
            backgroundColor: AppColors.lightGrey,
            textColor: AppColors.primary,
            showArrow: true,
            onTap: () {
              if (widget.isRescheduled && _selectedIndex == 0) return;
              Navigator.pop(context);
              if (_selectedIndex == 1) {
                Navigator.pushNamed(
                  context, 
                  AppRoutes.rescheduleBooking, 
                  arguments: {'isCancelMode': true, 'bookingId': widget.bookingId},
                );
              } else {
                Navigator.pushNamed(
                  context, 
                  AppRoutes.rescheduleBooking, 
                  arguments: {'isCancelMode': false, 'bookingId': widget.bookingId},
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOption({
    required int index,
    required String title,
    required bool isEnabled,
    String? disabledMessage,
  }) {
    final isSelected = _selectedIndex == index;
    final bgColor = isSelected ? AppColors.yellowDark : AppColors.blackColor2;
    // final borderColor = isSelected
    //     ? AppColors.primary.withOpacity(0.3)
    //     : AppColors.errorRed;

    Widget optionWidget = GestureDetector(
      onTap: () {
        if (!isEnabled) return;
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          // border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.medium(
              title,
              color: isSelected
                  ? AppColors.yellowColorLight
                  : AppColors.textPrimary,
              fontSize: 16,
            ),
            AppSvg(
              isSelected ? AppAssets.radioButton : AppAssets.radioButton2,
              width: 24,
              height: 24,
              color: isSelected ? AppColors.primary : AppColors.greyBorder,
            ),
          ],
        ),
      ),
    );

    if (!isEnabled) {
      optionWidget = Opacity(opacity: 0.4, child: optionWidget);

      if (disabledMessage != null) {
        optionWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            optionWidget,
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppText.small(
                disabledMessage,
                color: AppColors.errorRed,
                fontSize: 12,
              ),
            ),
          ],
        );
      }
    }

    return optionWidget;
  }
}
