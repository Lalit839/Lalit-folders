import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_circle.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/sport_category_shimmer.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/venue_card_shimmer.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/banner_shimmer.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Shimmer
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppShimmer(child: ShimmerLine(width: 120, height: 20)),
                    SizedBox(height: 8),
                    AppShimmer(child: ShimmerLine(width: 160, height: 12)),
                  ],
                ),
              ),
              AppShimmer(child: ShimmerCircle(radius: 20)),
              SizedBox(width: 12),
              AppShimmer(child: ShimmerCircle(radius: 20)),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar Shimmer
          const AppShimmer(
            child: ShimmerBox(
              width: double.infinity,
              height: 48,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 24),

          // Categories Shimmer
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => const SportCategoryShimmer(),
            ),
          ),
          const SizedBox(height: 24),

          // Promo Banner Shimmer
          SizedBox(
            height: 74,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => const BannerShimmer(),
            ),
          ),
          const SizedBox(height: 32),

          // Venues Around You Section Title Shimmer
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmer(child: ShimmerLine(width: 160, height: 18)),
              AppShimmer(child: ShimmerLine(width: 60, height: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Venues Shimmer List
          const SizedBox(height: 384, child: Center(child: VenueCardShimmer())),
        ],
      ),
    );
  }
}
