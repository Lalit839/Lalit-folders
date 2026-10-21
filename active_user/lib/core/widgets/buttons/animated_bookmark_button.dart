import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';

class AnimatedBookmarkButton extends StatelessWidget {
  final bool initialBookmarked;
  final Future<bool> Function(bool isBookmarked)? onTap;
  final double size;
  final Color backgroundColor;

  const AnimatedBookmarkButton({
    super.key,
    required this.initialBookmarked,
    this.onTap,
    this.size = 42.0,
    this.backgroundColor = AppColors.lightGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: LikeButton(
          padding: EdgeInsets.zero,
          likeCountPadding:
              EdgeInsets.zero, // Strips the hidden 3px label padding!
          isLiked: initialBookmarked,
          onTap: onTap,
          size: 22.0,
          circleColor: const CircleColor(
            start: AppColors.primary,
            end: AppColors.primary),
          bubblesColor: const BubblesColor(
            dotPrimaryColor: AppColors.primary,
            dotSecondaryColor: Colors.white),
          likeBuilder: (bool isBookmarked) {
            return SizedBox(
              width: 22.0,
              height: 22.0,
              child: Center(
                child: AppSvg(
                  isBookmarked ? AppAssets.saveActive : AppAssets.saveInactive,
                  color: isBookmarked ? AppColors.primary : Colors.white,
                  height: 16,
                  width: 19)));
          })));
  }
}
