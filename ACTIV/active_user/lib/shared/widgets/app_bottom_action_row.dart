import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_action_bar.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_pill_button.dart';

import 'package:activ_user_app/shared/widgets/app_text.dart';

class AppBottomActionRow extends StatelessWidget {
  final String actionTitle;
  final VoidCallback? onActionTap;
  final Widget? leftContent;
  final String? title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Color backgroundColor;
  final Color borderColor;

  const AppBottomActionRow({
    super.key,
    required this.actionTitle,
    this.onActionTap,
    this.leftContent,
    this.title,
    this.subtitle,
    this.subtitleWidget,
    this.backgroundColor = AppColors.black,
    this.borderColor = AppColors.lightGreyBorder,
  });

  Widget _buildLeftContent() {
    if (leftContent != null) {
      return leftContent!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          AppText.bold(
            title!,
            color: AppColors.textPrimary,
            fontSize: 16),
        if (subtitle != null || subtitleWidget != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child:
                subtitleWidget ??
                AppText(
                  subtitle!,
                  color: AppColors.greyBorder,
                  fontSize: 16)),
      ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Row(
        children: [
          Expanded(child: _buildLeftContent()),
          AppPillButton(title: actionTitle, onTap: onActionTap),
        ]));
  }
}
