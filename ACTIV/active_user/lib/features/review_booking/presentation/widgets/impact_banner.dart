import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';


class ImpactBanner extends StatelessWidget {
  const ImpactBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        AppAssets.impactBanner,
        width: double.infinity,
        fit: BoxFit.cover));
  }
}
