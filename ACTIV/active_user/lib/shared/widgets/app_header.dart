import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackTap;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.onBackTap,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return SafeArea(
      bottom: false,
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Back Button with Circle Container
            if (canPop) ...[
              GestureDetector(
                onTap:
                    onBackTap ??
                    () {
                      Navigator.pop(context);
                    },
                child: AppSvg(
                  AppAssets.backArrow,
                  color: Colors.white,
                  height: 24,
                  width: 24,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Title Text
            Expanded(
              child: AppText(title, color: AppColors.textPrimary, fontSize: 18),
            ),

            // Optional Trailing Widget
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}
