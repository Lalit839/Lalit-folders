import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:flutter/material.dart';

class BookingOffersSection extends StatelessWidget {
  final List<Widget> offerCards;
  final VoidCallback onSeeAll;
  final bool isLoading;

  const BookingOffersSection({
    super.key,
    this.offerCards = const [],
    required this.onSeeAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubSectionHeader(
          title: 'Offers Available',
          onSeeAllTap: isLoading ? null : onSeeAll,
          trailingWidget: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        if (offerCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: offerCards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: card))
                  .toList())),
        ],
      ]);
  }
}
