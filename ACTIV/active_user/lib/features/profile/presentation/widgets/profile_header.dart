import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class ProfileHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;

  const ProfileHeader({super.key, required this.title, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          AppText(title, color: AppColors.white, fontSize: 20),
        ],
      ),
    );
  }
}
