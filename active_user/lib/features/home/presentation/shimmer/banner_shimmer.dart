import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';

class BannerShimmer extends StatelessWidget {
  const BannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: ShimmerBox(
        width: 341,
        height: 74,
        borderRadius: 12));
  }
}
