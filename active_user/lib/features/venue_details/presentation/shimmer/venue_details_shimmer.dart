import 'package:flutter/material.dart';
import 'package:activ_user_app/features/venue_details/presentation/shimmer/venue_image_shimmer.dart';

class VenueDetailsShimmer extends StatelessWidget {
  const VenueDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VenueImageShimmer(),
        SizedBox(height: 16),
        // Add more placeholders if a shimmer package is added
      ]);
  }
}
