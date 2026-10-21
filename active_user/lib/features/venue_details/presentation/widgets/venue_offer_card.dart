import 'package:flutter/material.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/shared/widgets/app_offer_card.dart';

class VenueOfferCard extends StatelessWidget {
  final VenueOffer offer;

  const VenueOfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return AppOfferCard(
      title: offer.title,
      description: offer.description,
      topBadgeText: offer.activityName,
    );
  }
}
