import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';

class VenueCardShimmer extends StatelessWidget {
  const VenueCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        width: 321,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerBox(width: 321, height: 244, borderRadius: 12),
            SizedBox(height: 12),
            ShimmerLine(width: 140, height: 18),
            SizedBox(height: 6),
            ShimmerLine(width: 180, height: 12),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: 74), // Centered relative to 321
              child: ShimmerBox(width: 173, height: 40, borderRadius: 56),
            ),
          ],
        ),
      ),
    );
  }
}
