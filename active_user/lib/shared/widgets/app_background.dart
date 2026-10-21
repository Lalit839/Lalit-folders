import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showGradient;

  const AppBackground({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Background Gradient Glow from SVG
          if (showGradient)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: size.width,
                child: const AppSvg(
                  AppAssets.bgColor,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Main Screen Content
          child,
        ],
      ),
    );
  }
}
