import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';

class BookingsShimmer extends StatelessWidget {
  const BookingsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: double.infinity,
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5)),
          child: const Row(
            children: [
              // Left Section Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppShimmer(
                      child: ShimmerLine(width: 140, height: 16)),
                    SizedBox(height: 8),
                    AppShimmer(
                      child: ShimmerLine(width: 180, height: 12)),
                  ])),
              SizedBox(width: 12),

              // Divider Shimmer
              AppShimmer(
                child: ShimmerBox(width: 1, height: 32, borderRadius: 0)),
              SizedBox(width: 16),

              // Right Section Shimmer
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppShimmer(
                    child: ShimmerLine(width: 60, height: 14)),
                  SizedBox(height: 6),
                  AppShimmer(
                    child: ShimmerLine(width: 50, height: 12)),
                ]),
            ]));
      });
  }
}
