import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/models/coupon_ui_model.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_card.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_empty_view.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_details_bottom_sheet.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class ApplyCouponsScreen extends StatefulWidget {
  final String? bookingAttemptId;
  const ApplyCouponsScreen({super.key, this.bookingAttemptId});
  @override
  State<ApplyCouponsScreen> createState() => _ApplyCouponsScreenState();
}

class _ApplyCouponsScreenState extends State<ApplyCouponsScreen> {
  bool _loading = true;
  String? _error;
  List<CouponUiModel> _coupons = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.bookingAttemptId == null) {
      setState(() { _loading = false; _error = 'Coupons become available after a slot is held.'; });
      return;
    }
    try {
      final items = await ActivApiClient.instance.getCoupons(bookingAttemptId: widget.bookingAttemptId);
      if (mounted) {
        setState(() {
          _coupons = items.whereType<Map<String, dynamic>>().map((item) => CouponUiModel(
            id: item['code']?.toString() ?? '', code: item['code']?.toString() ?? '',
            description: item['percentOff'] == null ? 'Offer available' : '${item['percentOff']}% off',
            minOrderValue: 0, discountAmount: 0, expiryDate: DateTime.tryParse('${item['endsAt']}') ?? DateTime.now(),
          )).toList();
          _loading = false;
        });
      }
    } on ActivApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _apply(CouponUiModel coupon) async {
    if (widget.bookingAttemptId == null) return;
    try {
      final result = await ActivApiClient.instance.applyCoupon(widget.bookingAttemptId!, coupon.code);
      final quote = result['quote'] as Map<String, dynamic>?;
      final discount = ((quote?['discount'] as num?) ?? 0).toDouble() / 100;
      if (mounted) Navigator.pop(context, CouponUiModel(id: coupon.id, code: coupon.code, description: coupon.description, minOrderValue: 0, discountAmount: discount, expiryDate: coupon.expiryDate));
    } on ActivApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background, appBar: AppHeader(title: 'Apply Coupons'),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(_error!, color: AppColors.greyBorder, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(title: 'Retry', onTap: _load),
          ],
        )))
      : _coupons.isEmpty ? const CouponEmptyView() : ListView(padding: const EdgeInsets.all(16), children: [
        const SubSectionHeader(title: 'Best Offers For You'), const SizedBox(height: 14),
        ..._coupons.map((coupon) => CouponCard(coupon: coupon, onApply: () => _apply(coupon), onInfoTap: () => showAppBottomSheet(context: context, title: 'Offer details', child: CouponDetailsBottomSheet(coupon: coupon, onApply: () => _apply(coupon))))),
      ]),
  );
}
