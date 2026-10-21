import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/venue_card_shimmer.dart';

class VenueSearchShimmer extends StatelessWidget {
  const VenueSearchShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Search Bar Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: AppShimmer(
              child: ShimmerBox(
                width: double.infinity,
                height: 50,
                borderRadius: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sport Filters Shimmer
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const AppShimmer(
                child: ShimmerBox(width: 80, height: 38, borderRadius: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Filter Chips Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const AppShimmer(
                  child: ShimmerBox(width: 70, height: 32, borderRadius: 20),
                ),
                const SizedBox(width: 12),
                const AppShimmer(
                  child: ShimmerBox(width: 80, height: 32, borderRadius: 20),
                ),
                const SizedBox(width: 12),
                const AppShimmer(
                  child: ShimmerBox(width: 90, height: 32, borderRadius: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Results Header Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: AppShimmer(child: ShimmerLine(width: 120, height: 16)),
          ),
          const SizedBox(height: 16),

          // Results List Shimmer
          ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => const VenueCardShimmer(),
          ),
        ],
      ),
    );
  }
}
