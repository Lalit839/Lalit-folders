import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class PlayEveryMomentBanner extends StatelessWidget {
  const PlayEveryMomentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextLine('PLAY'),
            _buildTextLine('EVERY'),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTextLine('M'),
                Align(
                  widthFactor:
                      0.75, // Reduces horizontal spacing around the icon
                  child: Transform.translate(
                    offset: const Offset(
                      0,
                      4,
                    ), // Shift down slightly so the ball itself (not its shadow) is centered with the text
                    child: Image.asset(
                      AppAssets.football,
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      color: AppColors.lightGrey,
                      colorBlendMode: BlendMode
                          .modulate, // Preserves the 3D shading instead of a flat fill
                    ),
                  ),
                ),
                _buildTextLine('MENT'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextLine(String text) {
    return AppText.bold(
      text,
      fontWeight: FontWeight.w900,
      fontSize: 70,
      color: AppColors.lightGrey,
      height: 69.87 / 70.43,
      letterSpacing: 0,
    );
  }
}
