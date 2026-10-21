import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class AppBottomSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final bool showDragHandle;

  const AppBottomSheetHeader({
    super.key,
    required this.title,
    this.onClose,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle) ...[
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGrey2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!showDragHandle) const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(title, color: AppColors.textPrimary, fontSize: 18),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose ?? () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: AppSvg(AppAssets.cross),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
