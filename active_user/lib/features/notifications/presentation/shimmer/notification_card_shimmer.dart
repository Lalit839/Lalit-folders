import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_circle.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';

class NotificationCardShimmer extends StatelessWidget {
  const NotificationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Placeholder
            const ShimmerCircle(radius: 18),
            const SizedBox(width: 16),
            // Text Details Placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerLine(width: 120, height: 14),
                      // Subtle read dot placeholder
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF222222),
                          shape: BoxShape.circle)),
                    ]),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerLine(width: double.infinity, height: 11),
                            SizedBox(height: 4),
                            ShimmerLine(width: 180, height: 11),
                          ])),
                      SizedBox(width: 16),
                      ShimmerLine(width: 50, height: 10),
                    ]),
                ])),
          ])));
  }
}
