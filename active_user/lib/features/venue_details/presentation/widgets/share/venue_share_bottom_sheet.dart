import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet_header.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/share/venue_share_preview.dart';
import 'package:activ_user_app/core/widgets/share/venue_share_actions.dart';

class VenueShareBottomSheet extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String sports;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final String shareUrl;
  final String shareContent;

  const VenueShareBottomSheet({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.sports,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.isSaved,
    required this.onSaveToggle,
    required this.shareUrl,
    required this.shareContent,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String name,
    required String sports,
    required String location,
    required double rating,
    required int reviewCount,
    required bool isSaved,
    required VoidCallback onSaveToggle,
    required String shareUrl,
    required String shareContent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueShareBottomSheet(
        imageUrl: imageUrl,
        name: name,
        sports: sports,
        location: location,
        rating: rating,
        reviewCount: reviewCount,
        isSaved: isSaved,
        onSaveToggle: onSaveToggle,
        shareUrl: shareUrl,
        shareContent: shareContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(
              title: 'Share Venue',
              showDragHandle: false,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VenueSharePreview(
                    imageUrl: imageUrl,
                    name: name,
                    sports: sports,
                    location: location,
                    rating: rating,
                    reviewCount: reviewCount,
                  ),
                  const SizedBox(height: 24),
                  Divider(color: AppColors.lightGreyBorder, height: 1),
                  const SizedBox(height: 16),
                  VenueShareActions(
                    isSaved: isSaved,
                    onSaveToggle: onSaveToggle,
                    shareUrl: shareUrl,
                    shareContent: shareContent,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
