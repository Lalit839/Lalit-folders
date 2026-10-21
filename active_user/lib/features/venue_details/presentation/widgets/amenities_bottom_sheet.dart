import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/shared/widgets/app_draggable_bottom_sheet.dart';

void showAmenitiesBottomSheet(
  BuildContext context,
  List<VenueAmenity> amenities,
) {
  showAppDraggableBottomSheet(
    context: context,
    title: 'Amenities Available',
    initialChildSize: 0.5,
    minChildSize: 0.4,
    maxChildSize: 0.9,
    builder: (context, scrollController) {
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        itemCount: amenities.length,
        separatorBuilder: (context, index) =>
            const Divider(color: AppColors.lightGreyBorder, height: 1),
        itemBuilder: (context, index) {
          final amenity = amenities[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppText.small(
                    amenity.name,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
