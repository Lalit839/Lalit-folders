import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class AppDivider extends StatelessWidget {
  final double verticalPadding;
  final Color color;

  const AppDivider({
    super.key,
    this.verticalPadding = 40.0,
    this.color = AppColors.lightGreyBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Divider(color: color, height: 1));
  }
}
