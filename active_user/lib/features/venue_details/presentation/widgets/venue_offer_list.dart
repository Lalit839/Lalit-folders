import 'package:flutter/material.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_offer_card.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class VenueOfferList extends StatelessWidget {
  final List<VenueOffer> offers;

  const VenueOfferList({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubSectionHeader(title: 'Offers Available'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: offers.map((offer) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: VenueOfferCard(offer: offer),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
