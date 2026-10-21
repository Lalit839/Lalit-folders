import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/core/widgets/image/app_svg_network.dart';

class VenueAmenityItem extends StatelessWidget {
  final VenueAmenity amenity;

  const VenueAmenityItem({super.key, required this.amenity});

  String _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('upi') || lower.contains('payment')) {
      return AppAssets.paymentSettings;
    } else if (lower.contains('seating') || lower.contains('lounge')) {
      return AppAssets.seatingLounge;
    } else if (lower.contains('chang') || lower.contains('room')) {
      return AppAssets.changingRoom;
    } else if (lower.contains('water') || lower.contains('drink')) {
      return AppAssets.drinkingWater;
    } else if (lower.contains('park')) {
      return AppAssets.parking;
    } else if (lower.contains('light') || lower.contains('flood')) {
      return AppAssets.floodLights;
    } else if (lower.contains('washroom') || lower.contains('toilet')) {
      return AppAssets.washroom;
    } else if (lower.contains('locker')) {
      return AppAssets.lockerRoom;
    } else if (lower.contains('first aid')) {
      return AppAssets.firstAid;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final networkIcon = amenity.iconUrl.isNotEmpty;
    final String iconPath = amenity.iconAsset.isNotEmpty ? amenity.iconAsset : _getAmenityIcon(amenity.name);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (networkIcon)
          AppSvgNetwork(
            amenity.iconUrl,
            width: 20,
            height: 20,
            color: AppColors.greyBorder,
            fallbackAsset: iconPath.isNotEmpty ? iconPath : 'assets/images/turf.jpg',
          )
        else if (iconPath.isNotEmpty)
          AppSvg(
            iconPath,
            width: 20,
            height: 20,
            color: AppColors.greyBorder,
          )
        else
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.greyBorder,
            size: 20,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: AppText.small(
            amenity.name,
            color: AppColors.greyBorder,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
