import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class VenueRulesSection extends StatelessWidget {
  final List<String> rules;

  const VenueRulesSection({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, right: 8),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.greyBorder,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: AppText.small(
                  rule,
                  color: AppColors.greyBorder,
                  fontSize: 16,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
