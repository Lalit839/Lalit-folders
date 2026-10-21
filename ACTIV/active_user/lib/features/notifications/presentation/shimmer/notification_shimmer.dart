import 'package:flutter/material.dart';
import 'package:activ_user_app/features/notifications/presentation/shimmer/notification_card_shimmer.dart';

class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 10, // Mock loading elements
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF222222),
        height: 1,
        thickness: 1,
      ),
      itemBuilder: (context, index) => const NotificationCardShimmer(),
    );
  }
}
