import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/models/coupon_ui_model.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_card.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_empty_view.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/widgets/coupon_details_bottom_sheet.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  bool _loading = true;
  String? _error;
  List<CouponUiModel> _coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ActivApiClient.instance.getCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = items
            .whereType<Map<String, dynamic>>()
            .map(_toUiModel)
            .toList();
        _loading = false;
      });
    } on ActivApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  CouponUiModel _toUiModel(Map<String, dynamic> item) {
    final percentOff = item['percentOff'];
    final amountOffPaise = item['amountOffPaise'];
    final description = percentOff is num
        ? '$percentOff% off'
        : (amountOffPaise is String || amountOffPaise is num
            ? 'Flat \u20B9${_toPaise(amountOffPaise) ~/ 100} off'
            : 'Offer available');
    return CouponUiModel(
      id: item['code']?.toString() ?? '',
      code: item['code']?.toString() ?? '',
      description: description,
      minOrderValue: 0,
      discountAmount: _toPaise(amountOffPaise) / 100,
      expiryDate:
          DateTime.tryParse('${item['endsAt']}') ?? DateTime.now(),
    );
  }

  static int _toPaise(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> _copyCode(CouponUiModel coupon) async {
    await Clipboard.setData(ClipboardData(text: coupon.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon code ${coupon.code} copied')),
    );
  }

  void _showDetails(CouponUiModel coupon) {
    showAppBottomSheet(
      context: context,
      title: 'Offer details',
      child: CouponDetailsBottomSheet(
        coupon: coupon,
        onApply: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: 'Coupons & Offers'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppText(
                            _error!,
                            color: AppColors.grey99,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            title: 'Retry',
                            onTap: _load,
                          ),
                        ],
                      ),
                    ),
                  )
                : _coupons.isEmpty
                    ? const CouponEmptyView()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SubSectionHeader(title: 'Best Offers For You'),
                          const SizedBox(height: 14),
                          ..._coupons.map(
                            (coupon) => CouponCard(
                              coupon: coupon,
                              actionLabel: 'Copy code',
                              onApply: () => _copyCode(coupon),
                              onInfoTap: () => _showDetails(coupon),
                            ),
                          ),
                        ],
                      ),
      );
}