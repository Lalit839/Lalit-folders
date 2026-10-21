import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/features/slot_booking/presentation/controllers/book_slot_controller.dart';
import 'package:activ_user_app/features/review_booking/presentation/models/price_breakdown_ui_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:activ_user_app/core/config/env_config.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/routes/app_routes.dart';

import 'package:activ_user_app/features/review_booking/presentation/widgets/selected_slot_card.dart';
import 'package:activ_user_app/features/review_booking/presentation/widgets/selected_courts_section.dart';
import 'package:activ_user_app/features/review_booking/presentation/widgets/selected_court_item.dart';
import 'package:activ_user_app/features/review_booking/presentation/widgets/booking_offers_section.dart';
import 'package:activ_user_app/features/review_booking/presentation/widgets/price_breakdown_card.dart';
import 'package:activ_user_app/features/review_booking/presentation/widgets/impact_banner.dart';
import 'package:activ_user_app/features/payment/presentation/models/payment_method_option.dart';
import 'package:activ_user_app/features/payment/presentation/screens/payment_options_screen.dart';
import 'package:activ_user_app/features/payment/presentation/services/razorpay_web_checkout.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_expandable_section.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_rules_section.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/screens/apply_coupons_screen.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/models/coupon_ui_model.dart';
import 'package:activ_user_app/shared/widgets/success_bottom_sheet.dart';
import 'package:activ_user_app/features/review_booking/presentation/models/booking_offer_ui_model.dart';
import 'package:lottie/lottie.dart';

class ReviewBookingScreen extends ConsumerStatefulWidget {
  const ReviewBookingScreen({super.key});

  @override
  ConsumerState<ReviewBookingScreen> createState() =>
      _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends ConsumerState<ReviewBookingScreen> {
  late final Razorpay _razorpay;

  final List<BookingOfferUiModel> appliedOffers = [];

  bool _showCelebration = false;
  bool _isCreatingOrder = false;
  bool _isPreparingCoupons = false;
  String? _attemptId;
  DateTime? _attemptCreatedAt;
  DateTime? _attemptExpiresAt;
  String? _paymentId;
  String? _bookingId;
  PaymentMethodOption _selectedPaymentMethod = PaymentMethodOption.googlePay;
  Map<String, dynamic> _quote = const {};
  Map<String, dynamic> _paymentProfile = const {};
  List<String> _venueRules = const [];
  String _cancellationPolicy = '';
  List<String> _faqs = const [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        _razorpay = Razorpay();
        _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
      } catch (_) {
        // Razorpay may be unavailable on some platform targets.
      }
    }
    _loadAttempt();
    _loadVenueContent();
    _loadPaymentProfile();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      try {
        _razorpay.clear();
      } catch (_) {}
    }
    super.dispose();
  }

  double get _currentTotalRupees {
    final total = _toNum(_quote['total']);
    return total / 100;
  }

  Future<void> _loadAttempt() async {
    final controller = ref.read(bookSlotControllerProvider.notifier);
    final slotId = controller.selectedSlotId;
    if (slotId == null) return;
    try {
      final attempt = await ActivApiClient.instance.createBookingAttempt(
        slotId,
        controller.playerCount,
      );
      if (!mounted) return;
      setState(() {
        _attemptId = attempt['attemptId']?.toString();
        _attemptCreatedAt = DateTime.now();
        _attemptExpiresAt = DateTime.tryParse(
          attempt['expiresAt']?.toString() ?? '',
        )?.toLocal();
        final quote = attempt['quote'];
        _quote = quote is Map<String, dynamic> ? quote : const {};
      });
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadVenueContent() async {
    final state = ref.read(bookSlotControllerProvider);
    final venueId = state.venueId;
    if (venueId == null) return;
    try {
      final venue = await ActivApiClient.instance.getVenue(venueId);
      if (!mounted) return;
      setState(() {
        _venueRules = (venue['rules'] as List? ?? [])
            .whereType<String>()
            .toList();
        _cancellationPolicy = venue['cancellationPolicy']?.toString() ?? '';
        _faqs = (venue['faqs'] as List? ?? [])
            .whereType<Map>()
            .map((item) => 'Q: ${item['question']}\nA: ${item['answer']}')
            .toList();
      });
    } on ActivApiException {
      // Venue policy content is optional.
    }
  }

  Future<void> _loadPaymentProfile() async {
    try {
      final profile = await ActivApiClient.instance.getProfile();
      if (!mounted) return;
      setState(() => _paymentProfile = profile);
    } on ActivApiException {
      // Payment can still proceed without profile prefill.
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    unawaited(
      _confirmPaymentPayload(
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      ),
    );
  }

  Future<void> _confirmPaymentPayload({
    required String? razorpayPaymentId,
    required String? razorpayOrderId,
    required String? razorpaySignature,
  }) async {
    final paymentId = _paymentId;
    if (paymentId == null ||
        razorpayPaymentId == null ||
        razorpayOrderId == null ||
        razorpaySignature == null) {
      _verifyPayment(paymentId);
      return;
    }
    try {
      await ActivApiClient.instance.confirmRazorpayPayment(
        paymentId: paymentId,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );
      _showPaymentResult(true);
    } on ActivApiException {
      _verifyPayment(paymentId);
    }
  }

  Future<void> _verifyPayment(String? paymentId) async {
    if (paymentId == null) {
      _showPaymentResult(true);
      return;
    }
    try {
      for (var i = 0; i < 16; i++) {
        final payment = await ActivApiClient.instance.getPayment(paymentId);
        final status = payment['status']?.toString();
        if (status == 'CAPTURED') {
          _showPaymentResult(true);
          return;
        }
        if (status == 'FAILED' || status == 'EXCEPTION_REVIEW') {
          _showPaymentResult(false);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 750));
      }
      _showPaymentPending();
    } on ActivApiException {
      _showPaymentPending();
    }
  }

  void _showPaymentPending() {
    if (!mounted) return;
    showSuccessBottomSheet(
      context: context,
      isError: false,
      title: 'Payment of ₹${_currentTotalRupees.toInt()} is being processed',
      subtitle:
          'We\'re confirming your payment. Your booking is reserved and will appear in your bookings once confirmed.',
      topPillText: 'Payment Pending',
      primaryButtonText: 'View Booking Details',
      onPrimaryButtonTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetails,
          arguments: {'status': 'success', 'bookingId': _bookingId},
        );
      },
      secondaryButtonText: 'Back to Home',
      onSecondaryButtonTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    _showPaymentResult(false);
  }

  void _showPaymentResult(bool success) {
    if (!mounted) return;
    showSuccessBottomSheet(
      context: context,
      isError: !success,
      title: success
          ? 'Payment of ₹${_currentTotalRupees.toInt()} Complete'
          : 'Payment of ₹${_currentTotalRupees.toInt()} failed',
      subtitle: success
          ? 'Your Court is reserved. Get ready to\nplay your best game yet.'
          : 'If amount was deducted from your selected payment method, refund will be processed within 24 hours',
      topPillText: success ? 'Transaction Successful' : 'Transaction Failed',
      primaryButtonText: success ? 'View Booking Details' : 'Retry payment',
      onPrimaryButtonTap: success
          ? () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushNamed(
                context,
                AppRoutes.bookingDetails,
                arguments: {'status': 'success', 'bookingId': _bookingId},
              );
            }
          : () {
              Navigator.pop(context);
              _startPayment();
            },
      secondaryButtonText: 'Back to Home',
      onSecondaryButtonTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  Future<void> _startPayment() async {
    if (_isCreatingOrder) return;
    final controller = ref.read(bookSlotControllerProvider.notifier);
    final slotId = controller.selectedSlotId;
    if (slotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an available slot first.')),
      );
      return;
    }
    setState(() => _isCreatingOrder = true);
    try {
      var attemptId = _attemptId;
      if (attemptId == null ||
          _attemptCreatedAt == null ||
          DateTime.now().difference(_attemptCreatedAt!) >
              const Duration(minutes: 5)) {
        final attempt = await ActivApiClient.instance.createBookingAttempt(
          slotId,
          controller.playerCount,
        );
        attemptId = attempt['attemptId']?.toString();
        _attemptCreatedAt = DateTime.now();
        _attemptExpiresAt = DateTime.tryParse(
          attempt['expiresAt']?.toString() ?? '',
        )?.toLocal();
        _attemptId = attemptId;
      }
      if (attemptId == null) {
        throw const ActivApiException('Booking attempt was not created.', 0);
      }
      Map<String, dynamic> order;
      try {
        order = await ActivApiClient.instance.createPaymentOrder(attemptId);
      } on ActivApiException catch (error) {
        // The booking attempt may have expired or been consumed (409).
        // A stale browser session can also reject the first attempt (401).
        if (error.statusCode == 409) {
          _attemptId = null;
          _attemptCreatedAt = null;
          final attempt = await ActivApiClient.instance.createBookingAttempt(
            slotId,
            controller.playerCount,
          );
          final freshAttemptId = attempt['attemptId']?.toString();
          if (freshAttemptId == null) rethrow;
          _attemptId = freshAttemptId;
          _attemptCreatedAt = DateTime.now();
          _attemptExpiresAt = DateTime.tryParse(
            attempt['expiresAt']?.toString() ?? '',
          )?.toLocal();
          order = await ActivApiClient.instance.createPaymentOrder(
            freshAttemptId,
          );
        } else {
          rethrow;
        }
      }
      _paymentId = order['paymentId']?.toString();
      _bookingId = order['bookingId']?.toString();
      final orderId = order['orderId']?.toString();
      if (orderId == null && order['demo'] != true) {
        throw const ActivApiException('Payment order was not created.', 0);
      }
      final amountPaise = _toNum(order['amount']);
      if (order['demo'] == true) {
        _verifyPayment(_paymentId);
        return;
      }
      final key = EnvConfig.razorpayKeyId;
      if (key.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Razorpay key is not configured.')),
          );
        }
        return;
      }
      final contact = _normalizedPaymentContact();
      final email = _paymentEmail();
      final name = _paymentName();
      final useDirectUpiIntent =
          !kIsWeb &&
          !_isRazorpayTestKey(key) &&
          _selectedPaymentMethod.type == PaymentMethodType.upi &&
          _selectedPaymentMethod.upiAppPackageName != null;
      final lockCheckoutMethod =
          _selectedPaymentMethod.type == PaymentMethodType.card ||
          useDirectUpiIntent ||
          _selectedPaymentMethod.wallet != null;
      final checkoutOptions = <String, dynamic>{
        'key': key,
        'order_id': orderId,
        'amount': amountPaise,
        'name': 'Activ Booking',
        'description': _selectedPaymentMethod.title,
        'currency': order['currency']?.toString() ?? 'INR',
        if (lockCheckoutMethod) 'method': _selectedPaymentMethod.checkoutMethod,
        if (useDirectUpiIntent) ...{
          '_[flow]': 'intent',
          'upi_app_package_name': _selectedPaymentMethod.upiAppPackageName,
        },
        'contact': ?contact,
        'email': ?email,
        'prefill': {'name': ?name, 'contact': ?contact, 'email': ?email},
        'readonly': {
          if (contact != null) 'contact': true,
          if (email != null) 'email': true,
        },
        if (_selectedPaymentMethod.wallet != null)
          'wallet': _selectedPaymentMethod.wallet,
        if (_selectedPaymentMethod.wallet != null)
          'external': {
            'wallets': [_selectedPaymentMethod.wallet],
          },
        'theme': {'color': '#DAFF50'},
      };
      if (kIsWeb) {
        await openRazorpayWebCheckout(
          options: checkoutOptions,
          onSuccess: (result) {
            unawaited(
              _confirmPaymentPayload(
                razorpayPaymentId: result.paymentId,
                razorpayOrderId: result.orderId,
                razorpaySignature: result.signature,
              ),
            );
          },
          onFailure: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
        );
        return;
      }
      _razorpay.open({...checkoutOptions});
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  String? _paymentName() {
    final value = _paymentProfile['name']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    final cached = SharedPrefService.userName?.trim();
    return cached?.isNotEmpty == true ? cached : null;
  }

  String? _paymentEmail() {
    final value = _paymentProfile['email']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    final cached = SharedPrefService.userEmail?.trim();
    return cached?.isNotEmpty == true ? cached : null;
  }

  String? _normalizedPaymentContact() {
    final raw =
        _paymentProfile['phoneE164']?.toString() ??
        _paymentProfile['phone']?.toString();
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return null;
  }

  bool _isRazorpayTestKey(String key) {
    return key.trim().startsWith('rzp_test_');
  }

  Future<void> _navigateToApplyCoupons() async {
    setState(() => _isPreparingCoupons = true);
    try {
      final needsAttempt =
          _attemptId == null ||
          _attemptCreatedAt == null ||
          DateTime.now().difference(_attemptCreatedAt!) >
              const Duration(minutes: 8);
      if (needsAttempt) {
        final controller = ref.read(bookSlotControllerProvider.notifier);
        final slotId = controller.selectedSlotId;
        if (slotId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select an available slot first.')),
          );
          return;
        }
        final attempt = await ActivApiClient.instance.createBookingAttempt(
          slotId,
          controller.playerCount,
        );
        _attemptId = attempt['attemptId']?.toString();
        _attemptCreatedAt = DateTime.now();
        _attemptExpiresAt = DateTime.tryParse(
          attempt['expiresAt']?.toString() ?? '',
        )?.toLocal();
        final quote = attempt['quote'];
        if (quote is Map<String, dynamic>) _quote = quote;
      }
      if (!mounted) return;
      final result = await Navigator.push<CouponUiModel>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ApplyCouponsScreen(bookingAttemptId: _attemptId),
        ),
      );

      if (result != null) {
        await _refreshQuote();
        if (!mounted) return;
        setState(() {
          appliedOffers.add(
            BookingOfferUiModel(
              code: result.code,
              description: result.description,
              discountAmount: _toNum(_quote['discount']) / 100,
            ),
          );
          _showCelebration = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showCelebration = false;
            });
          }
        });
      }
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isPreparingCoupons = false);
    }
  }

  Future<void> _removeOffer(BookingOfferUiModel offer) async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    try {
      await ActivApiClient.instance.removeCoupon(attemptId);
      await _refreshQuote();
      if (!mounted) return;
      setState(() {
        appliedOffers.remove(offer);
      });
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _refreshQuote() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    try {
      final attempt = await ActivApiClient.instance.getBookingAttempt(
        attemptId,
      );
      if (!mounted) return;
      setState(() {
        final quote = attempt['quote'];
        _quote = quote is Map<String, dynamic> ? quote : const {};
      });
    } on ActivApiException {
      // Keep the last known quote.
    }
  }

  Future<void> _openPaymentOptions(int amountRupees) async {
    final result = await Navigator.push<PaymentSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentOptionsScreen(
          amountRupees: amountRupees,
          expiresAt: _attemptExpiresAt,
          selectedMethod: _selectedPaymentMethod,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedPaymentMethod = result.method);
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookSlotControllerProvider);
    final bookController = ref.read(bookSlotControllerProvider.notifier);

    final couponDiscount = appliedOffers.fold<double>(
      0,
      (sum, offer) => sum + offer.discountAmount,
    );

    final quoteDiscount = _toNum(_quote['discount']) / 100;
    final discount = couponDiscount > 0 ? couponDiscount : quoteDiscount;
    final breakdown = PriceBreakdownUiModel(
      slotPrice: _toNum(_quote['subtotal']) / 100,
      serviceFee: _toNum(_quote['fees']) / 100,
      discount: discount,
      gstPercentage: _toNum(_quote['tax']) > 0 ? 18 : 0,
      gstAmount: _toNum(_quote['tax']) / 100,
      totalAmount: _toNum(_quote['total']) > 0
          ? _toNum(_quote['total']) / 100
          : (_toNum(_quote['subtotal']) / 100 - discount),
    );

    final dateStr = bookState.selectedDate != null
        ? DateFormat('EEEE, d MMM').format(bookState.selectedDate!)
        : '';
    String timeStr = '';
    if (bookState.selectedStartTime != null) {
      final end = bookState.selectedStartTime!.add(
        Duration(minutes: bookState.selectedDurationMinutes),
      );
      timeStr =
          '${DateFormat('h').format(bookState.selectedStartTime!)} - ${DateFormat('h a').format(end)}';
    }

    final selectedCourts = bookController
        .getAvailableCourtsForSelectedTime()
        .where((c) => bookState.selectedCourtIds.contains(c.id))
        .map(
          (court) => SelectedCourtItem(
            courtName: court.name,
            type: court.venueType,
            format: '${bookState.playerCount} spots',
            price: court.price,
          ),
        )
        .toList();

    final venueName = bookState.venueName ?? 'ACTIV Venue';
    final venueLocation = bookState.venueCity ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppHeader(title: 'Review Booking'),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VenueSummaryCard(
                        imageUrl: null,
                        name: venueName,
                        sport: bookState.selectedActivity ?? 'Activity',
                        location: venueLocation,
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectedSlotCard(
                              userName:
                                  SharedPrefService.userName?.isNotEmpty == true
                                  ? SharedPrefService.userName!
                                  : 'You',
                              date: dateStr,
                              time: timeStr,
                            ),
                            AppDivider(verticalPadding: 16),
                            SelectedCourtsSection(children: selectedCourts),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      BookingOffersSection(
                        offerCards: appliedOffers
                            .map(
                              (offer) => AppOfferCard(
                                title: offer.code,
                                description: offer.description,
                                isFullWidth: true,
                                onRemove: () => _removeOffer(offer),
                              ),
                            )
                            .toList(),
                        onSeeAll: _navigateToApplyCoupons,
                        isLoading: _isPreparingCoupons,
                        fullWidthCards: true,
                      ),
                      const SizedBox(height: 40),
                      PriceBreakdownCard(breakdown: breakdown),
                      const SizedBox(height: 24),
                      const ImpactBanner(),
                      AppDivider(verticalPadding: 40),
                      VenueExpandableSection(
                        title: 'Venue Rules',
                        iconAsset: AppAssets.venueRules,
                        child: VenueRulesSection(rules: _venueRules),
                      ),
                      const SizedBox(height: 24),
                      VenueExpandableSection(
                        title: 'Cancellation Policy',
                        iconAsset: AppAssets.venueRules,
                        child: AppText(
                          _cancellationPolicy,
                          color: AppColors.greyBorder,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      VenueExpandableSection(
                        title: 'FAQs',
                        iconAsset: AppAssets.faqs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final faq in _faqs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AppText(
                                  faq,
                                  color: AppColors.greyBorder,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              AppBottomActionRow(
                leftContent: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      _openPaymentOptions(breakdown.totalAmount.toInt()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.bold(
                        '₹${breakdown.totalAmount.toInt()}',
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AppText(
                              _selectedPaymentMethod.title,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actionTitle: 'Pay Now',
                onActionTap: _isCreatingOrder ? null : _startPayment,
              ),
            ],
          ),
        ),
        if (_showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/animations/celebrate.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  double _toNum(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
