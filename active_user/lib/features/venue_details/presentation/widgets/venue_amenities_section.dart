import 'package:flutter/material.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_amenity_item.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/core/widgets/buttons/action_text_button.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/amenities_bottom_sheet.dart';

class VenueAmenitiesSection extends StatelessWidget {
  final List<VenueAmenity> amenities;

  const VenueAmenitiesSection({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'Amenities'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 14,
          ),
          itemCount: amenities.length,
          itemBuilder: (context, index) {
            return VenueAmenityItem(amenity: amenities[index]);
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: ActionTextButton(
            label: 'View All',
            onTap: () {
              showAmenitiesBottomSheet(context, amenities);
            },
          ),
        ),
      ],
    );
  }
}
