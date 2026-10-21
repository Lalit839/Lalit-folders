import 'package:flutter/material.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_circle.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_line.dart';

class SportCategoryShimmer extends StatelessWidget {
  const SportCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: 84,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x0DFFFFFF), width: 1)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerCircle(radius: 22),
            SizedBox(height: 12),
            ShimmerLine(width: 50, height: 10),
          ])));
  }
}
