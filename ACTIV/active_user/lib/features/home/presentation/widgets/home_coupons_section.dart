import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/widgets/common/section_header.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/app_offer_card.dart';
import 'package:flutter/material.dart';

class HomeCouponsSection extends StatefulWidget {
  const HomeCouponsSection({super.key});

  @override
  State<HomeCouponsSection> createState() => _HomeCouponsSectionState();
}

class _HomeCouponsSectionState extends State<HomeCouponsSection> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ActivApiClient.instance.getCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = items.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } on ActivApiException {
      if (mounted) {
        setState(() {
          _error = 'Coupons unavailable';
          _loading = false;
        });
      }
    }
  }

  String _description(Map<String, dynamic> coupon) {
    final percentOff = coupon['percentOff'];
    if (percentOff is num) return '$percentOff% off';
    final amountOffPaise = coupon['amountOffPaise'];
    if (amountOffPaise is num) return 'Flat \u20B9${amountOffPaise ~/ 100} off';
    return 'Offer available';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_error != null || _coupons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Coupons & Offers',
          showSeeAll: true,
          onSeeAllTap: () {
            Navigator.pushNamed(context, AppRoutes.coupons);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _coupons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final coupon = _coupons[index];
              final code = coupon['code']?.toString() ?? '';
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.coupons);
                },
                child: AppOfferCard(
                  title: code,
                  description: _description(coupon),
                  topBadgeText: 'COUPON',
                  isFullWidth: false,
                ),
              );
            },
          ),
        ),

      ],
    );
  }
}