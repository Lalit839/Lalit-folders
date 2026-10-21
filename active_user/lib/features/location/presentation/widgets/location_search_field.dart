import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class LocationSearchField extends StatelessWidget {
  const LocationSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Search city, area or locality',
        prefixIcon: Icon(Icons.search, color: AppColors.grey)));
  }
}
