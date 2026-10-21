import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/cards/venue_card.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class VenueResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> venues;

  const VenueResultsList({super.key, required this.venues});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      itemCount: venues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final venue = venues[index];
        return VenueCard(
          title: venue['name']?.toString() ?? venue['title']?.toString() ?? '',
          imagePath:
              venue['image']?.toString() ?? venue['imagePath']?.toString() ?? '',
          distance: venue['distance']?.toString() ?? '',
          location: venue['location']?.toString() ?? '',
          discount:
              venue['offer']?.toString() ?? venue['discount']?.toString() ?? '',
          rating: (venue['rating'] ?? 0.0).toDouble(),
          reviews: (venue['reviews'] ?? 0).toInt(),
          id: venue['id']?.toString(),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.venueDetails, arguments: {'venueId': venue['id']?.toString()});
          },
        );
      },
    );
  }
}
