import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/cards/venue_card.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class VenueResultsSliverList extends StatelessWidget {
  final List<Map<String, dynamic>> venues;

  const VenueResultsSliverList({super.key, required this.venues});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final venue = venues[index];
            final images = (venue['imageUrls'] as List?) ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 0.0), // match separator height
              child: VenueCard(
                title: venue['name']?.toString() ?? venue['title']?.toString() ?? '',
                imagePath: venue['image']?.toString() ??
                    venue['imagePath']?.toString() ??
                    (images.isNotEmpty ? images.first.toString() : ''),
                imageUrls: images.cast<String>(),
                distance: venue['distance']?.toString() ?? '',
                location: venue['location']?.toString() ?? '',
                discount: venue['offer']?.toString() ??
                    venue['discount']?.toString() ??
                    '',
                rating: (venue['rating'] ?? 0.0).toDouble(),
                reviews: (venue['reviews'] ?? 0).toInt(),
                id: venue['id']?.toString(),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.venueDetails, arguments: {'venueId': venue['id']?.toString()});
                },
              ),
            );
          },
          childCount: venues.length,
        ),
      ),
    );
  }
}
