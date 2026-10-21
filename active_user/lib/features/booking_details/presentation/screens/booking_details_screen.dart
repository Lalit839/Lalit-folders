import 'dart:async';

import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/booking_ticket_card.dart';
import 'package:activ_user_app/core/widgets/share/venue_share_actions.dart';
import 'package:activ_user_app/features/my_bookings/presentation/widgets/modify_booking_bottom_sheet.dart';
import 'package:activ_user_app/features/booking_details/presentation/widgets/refund_status_bottom_sheet.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isSaved = false;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _booking;

  Map<String, dynamic>? get _routeArgs =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  String? get _bookingId => _routeArgs?['bookingId']?.toString();

  String? get _routeStatus => _routeArgs?['status']?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
  }

  Future<void> _loadBooking() async {
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Booking ID is missing.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final booking = await ActivApiClient.instance.getBooking(bookingId);
      final savedVenues = await ActivApiClient.instance.getSavedVenues();
      final slot = (booking['slot'] as Map<String, dynamic>?) ?? {};
      final facility = (slot['facility'] as Map<String, dynamic>?) ?? {};
      final venue = (facility['venue'] as Map<String, dynamic>?) ?? {};
      final venueId = venue['id']?.toString();
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isSaved = venueId != null &&
            savedVenues.any(
              (item) =>
                  item is Map<String, dynamic> &&
                  (item['venue'] as Map<String, dynamic>?)?['id'] == venueId,
            );
      });
    } on ActivApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVenueSave() async {
    final slot = (_booking?['slot'] as Map<String, dynamic>?) ?? {};
    final facility = (slot['facility'] as Map<String, dynamic>?) ?? {};
    final venue = (facility['venue'] as Map<String, dynamic>?) ?? {};
    final venueId = venue['id']?.toString();
    if (venueId == null || venueId.isEmpty) return;

    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
    });
    try {
      if (wasSaved) {
        await ActivApiClient.instance.removeSavedVenue(venueId);
      } else {
        await ActivApiClient.instance.saveVenue(venueId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaved = wasSaved;
      });
    }
  }

  Future<void> _openDirections() async {
    final slot = (_booking?['slot'] as Map<String, dynamic>?) ?? {};
    final facility = (slot['facility'] as Map<String, dynamic>?) ?? {};
    final venue = (facility['venue'] as Map<String, dynamic>?) ?? {};
    if (venue.isEmpty) return;

    final latitude = num.tryParse('${venue['latitude']}');
    final longitude = num.tryParse('${venue['longitude']}');
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else {
      final query = Uri.encodeComponent(
        '${venue['name'] ?? ''} ${venue['cityCode'] ?? ''}',
      );
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps.')),
      );
    }
  }

  void _showRefundStatus() {
    final booking = _booking;
    final refunds = (booking?['refunds'] as List?) ?? const [];
    if (refunds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No refund has been initiated for this booking yet.',
          ),
        ),
      );
      return;
    }

    final refund = refunds.first as Map<String, dynamic>? ?? {};

    RefundStatusBottomSheet.show(
      context,
      booking: booking ?? {},
      refund: refund,
    );
  }

  BookingTicketStatus get _ticketStatus {
    final status = _booking?['status']?.toString().toLowerCase() ??
        _routeStatus?.toLowerCase() ??
        'confirmed';
    if (status == 'cancelled' || status == 'canceled') {
      return BookingTicketStatus.cancelled;
    }
    if (status == 'completed') return BookingTicketStatus.completed;
    final rescheduleCount = num.tryParse('${_booking?['rescheduleCount']}') ?? 0;
    if (status == 'rescheduled' || rescheduleCount > 0) {
      return BookingTicketStatus.rescheduled;
    }
    return BookingTicketStatus.active;
  }

  bool get _isSuccess => _routeStatus?.toLowerCase() == 'success';

  String _formatDate(String? iso) {
    final time = DateTime.tryParse(iso ?? '');
    return time == null ? '' : DateFormat('EEEE, d MMMM yyyy').format(time.toLocal());
  }

  String _formatTime(String? iso) {
    final time = DateTime.tryParse(iso ?? '');
    return time == null ? '' : DateFormat('h:mm a').format(time.toLocal());
  }

  String _formatInr(dynamic paise) {
    final value = num.tryParse('$paise') ?? 0;
    return '₹${NumberFormat('#,##0').format((value / 100).round())}';
  }

  int? _capturedPaymentIndex() {
    final payments = _booking?['payments'];
    if (payments is! List) return null;
    for (var i = 0; i < payments.length; i++) {
      final item = payments[i];
      if (item is Map<String, dynamic> &&
          (item['status']?.toString().toUpperCase() == 'CAPTURED')) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _ticketStatus == BookingTicketStatus.cancelled;
    final isRescheduled = _ticketStatus == BookingTicketStatus.rescheduled;
    final isCompleted = _ticketStatus == BookingTicketStatus.completed;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeader(title: 'Venue info'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final slot = (booking?['slot'] as Map<String, dynamic>?) ?? {};
    final facility = (slot['facility'] as Map<String, dynamic>?) ?? {};
    final venue = (facility['venue'] as Map<String, dynamic>?) ?? {};
    final attempt = (booking?['attempt'] as Map<String, dynamic>?) ?? {};
    final capturedPayment = _capturedPaymentIndex();
    final payments = booking?['payments'];
    final payment = (capturedPayment != null && payments is List)
        ? payments[capturedPayment]
        : null;
    final paymentMap = payment is Map<String, dynamic> ? payment : null;

    final venueName = venue['name']?.toString() ?? 'ACTIV Venue';
    final facilityName = facility['name']?.toString() ?? 'Activity';
    final cityCode = venue['cityCode']?.toString() ?? '';
    final quantity = num.tryParse('${attempt['quantity']}') ?? 1;
    final amountPaise =
        paymentMap?['amountPaise'] ?? booking?['totalPaise'] ?? 0;

    if (_error != null && booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: _isSuccess ? 'Transaction Successful' : 'Venue info'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: AppText.small(
                _error!,
                color: AppColors.grey99,
                fontSize: 16,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: (_isSuccess
              ? AppBar(
                  backgroundColor: AppColors.greenColorLight,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 16,
                  toolbarHeight: 70,
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          AppAssets.backArrow,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textPrimary,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText.medium(
                            'Transaction Successful',
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                          const SizedBox(height: 2),
                          AppText.small(
                            _formatTime(
                              paymentMap?['createdAt']?.toString() ??
                                  booking?['createdAt']?.toString(),
                            ),
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : AppHeader(
                  title: 'Venue info',
                  trailing:
                      (booking != null &&
                          _ticketStatus != BookingTicketStatus.active &&
                          _ticketStatus != BookingTicketStatus.completed)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? AppColors.errorRed
                                : AppColors.yellowDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText.bold(
                            isCancelled ? 'Cancelled' : 'Rescheduled',
                            color: isCancelled
                                ? Colors.white
                                : AppColors.primary,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ))
          as PreferredSizeWidget?,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSuccess) ...[
                AppText.bold(
                  'Paid to',
                  color: AppColors.greyBorder,
                  fontSize: 18,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.purpleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppText.bold(
                          _initials(venueName),
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            venueName,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                          const SizedBox(height: 2),
                          AppText.small(
                            'Booking Confirmed!',
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ),
                    AppText.bold(
                      _formatInr(amountPaise),
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              BookingTicketCard(
                status: _ticketStatus,
                date: _formatDate(booking?['startsAt']?.toString()),
                venueName: venueName,
                address: cityCode,
                activity: facilityName,
                slot:
                    '${_formatTime(booking?['startsAt']?.toString())} - ${_formatTime(slot['endsAt']?.toString())}',
                courts: [facilityName],
                type: cityCode,
                totalPlayers: '$quantity',
                amountPaid: _formatInr(amountPaise),
                bookingId:
                    booking?['publicCode']?.toString() ??
                    (_bookingId ?? ''),
                onGetDirection: _openDirections,
              ),

              const SizedBox(height: 24),

              AppButton(
                title: isCompleted
                    ? 'Rate Venue'
                    : (isCancelled ? 'Track My Refund' : 'Modify Booking'),
                onTap: () {
                  if (isCompleted) {
                    if (booking == null) return;
                    Navigator.pushNamed(
                      context,
                      AppRoutes.rateActiv,
                      arguments: {
                        'isVenueReview': true,
                        'bookingId': _bookingId,
                        'venueName': '$facilityName at $venueName',
                        'bookingTime': _bookingTimeLabel(),
                      },
                    );
                  } else if (isCancelled) {
                    _showRefundStatus();
                  } else if (booking != null) {
                    ModifyBookingBottomSheet.show(
                      context,
                      isRescheduled: isRescheduled,
                      bookingId: _bookingId,
                    );
                  }
                },
                backgroundColor: AppColors.blackColor2,
                textColor: AppColors.primary,
                showArrow: true,
              ),

              const SizedBox(height: 40),
              AppDivider(verticalPadding: 0),
              const SizedBox(height: 16),

              VenueShareActions(
                isSaved: _isSaved,
                onSaveToggle: () {
                  unawaited(_toggleVenueSave());
                },
                shareUrl: 'https://activ.app/venue/$facilityName',
                shareContent: 'Check out my booking at $venueName!',
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _bookingTimeLabel() {
    final startsAt = _booking?['startsAt']?.toString();
    final slot = (_booking?['slot'] as Map<String, dynamic>?) ?? {};
    final start = DateTime.tryParse(startsAt ?? '');
    final end = DateTime.tryParse(slot['endsAt']?.toString() ?? '');
    if (start == null) return '';
    final day = DateFormat('EEEE, d MMMM yyyy').format(start.toLocal());
    final time =
        '${DateFormat('h:mm a').format(start.toLocal())} - '
        '${end == null ? '' : DateFormat('h:mm a').format(end.toLocal())}';
    return '$day, $time';
  }

  String _initials(String name) {
    final parts =
        name.split(' ').where((part) => part.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return 'AC';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
