import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class ProfileUserInfo extends StatelessWidget {
  final String userName;
  final String userPhone;
  final String? userEmail;
  final String? profilePhotoBase64;
  final VoidCallback onEditProfile;

  const ProfileUserInfo({
    super.key,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    this.profilePhotoBase64,
    required this.onEditProfile,
  });

  String _formatPhone(String phone) {
    if (phone.contains('00000000')) {
      return '+91 12345-67890';
    }
    if (phone.startsWith('+91') && phone.length == 13) {
      return '+91 ${phone.substring(3, 8)}-${phone.substring(8)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final photoBase64 = profilePhotoBase64;
    final hasPhoto = photoBase64 != null && photoBase64.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.blackColor2,
          backgroundImage: hasPhoto
              ? MemoryImage(base64Decode(photoBase64))
              : null,
          child: hasPhoto
              ? null
              : AppSvg(AppAssets.navProfile, width: 40, height: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bold(
                userName,
                color: AppColors.textPrimary,
                fontSize: 18,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (userPhone.isNotEmpty)
                AppText(
                  _formatPhone(userPhone),
                  color: AppColors.grey99,
                  fontSize: 14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (userEmail != null && userEmail!.isNotEmpty)
                AppText(
                  userEmail!,
                  color: AppColors.grey99,
                  fontSize: 14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onEditProfile,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: AppColors.lightGreyBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            backgroundColor: Colors.transparent,
          ),
          child: AppText.medium(
            'Edit profile',
            color: AppColors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
