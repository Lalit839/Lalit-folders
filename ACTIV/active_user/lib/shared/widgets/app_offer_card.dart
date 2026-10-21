import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class AppOfferCard extends StatelessWidget {
  final String title;
  final String description;
  final String? topBadgeText;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final bool isFullWidth;

  const AppOfferCard({
    super.key,
    required this.title,
    required this.description,
    this.topBadgeText,
    this.onRemove,
    this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: isFullWidth ? double.infinity : 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: (topBadgeText != null && topBadgeText!.isNotEmpty) ? 10 : 0),
            constraints: const BoxConstraints(minHeight: 72),
            padding: EdgeInsets.only(
              top: 16,
              right: isFullWidth ? 16 : 12,
              bottom: 16,
              left: 12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF425188), Color(0xFF6F4385)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGreyBorder, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // The % icon inside a black circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppText.bold(
                    '%',
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Text Content
                Expanded(
                  child: _buildTextContent(),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: AppColors.white),
                      ),
                    ),
                    child: AppText.bold(
                      'Remove',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (topBadgeText != null && topBadgeText!.isNotEmpty)
            Positioned(
              top: 0,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.lightGreyBorder,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: AppText.medium(
                  topBadgeText!,
                  color: AppColors.greyBorder,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildTextContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bold(
          title,
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        const SizedBox(height: 2),
        AppText.small(
          description,
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ],
    );
  }
}


