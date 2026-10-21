import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/share/share_action_item.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/core/services/share_service.dart';

class VenueShareActions extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final String shareUrl;
  final String shareContent;

  const VenueShareActions({
    super.key,
    required this.isSaved,
    required this.onSaveToggle,
    required this.shareUrl,
    required this.shareContent,
  });

  @override
  Widget build(BuildContext context) {
    final shareService = ShareService();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShareActionItem(
          icon: AppSvg(
            isSaved ? AppAssets.saveActive : AppAssets.saveInactive,
            color: isSaved ? AppColors.primary : AppColors.white,
            width: 16,
            height: 18),
          label: 'Save Venue',
          onTap: onSaveToggle),
        ShareActionItem(
          icon: AppSvg(AppAssets.link),
          label: 'Copy Link',
          onTap: () {
            shareService.copyVenueLink(shareUrl);
          }),
        ShareActionItem(
          icon: AppSvg(AppAssets.share, width: 22, height: 22),
          label: 'Share',
          onTap: () {
            shareService.shareVenue(shareContent);
          }),
        ShareActionItem(
          icon: AppSvg(AppAssets.whatsappIcon, width: 24, height: 24),
          label: 'WhatsApp',
          onTap: () {
            shareService.shareVenueOnWhatsApp(
              shareContent,
              onWhatsAppNotInstalled: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp is not installed on your device')));
              });
          }),
      ]);
  }
}
