import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/shared/widgets/venue_summary_card.dart';
import 'package:activ_user_app/shared/widgets/app_card.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_expandable_section.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_rules_section.dart';
import 'package:activ_user_app/shared/widgets/inputs/app_selection_bottom_sheet.dart';
import 'package:activ_user_app/features/slot_booking/presentation/screens/book_your_slot_screen.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/confirm_reschedule_bottom_sheet.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:intl/intl.dart';

class RescheduleBookingScreen extends StatefulWidget {
  final bool isCancelMode;
  final String? bookingId;
  const RescheduleBookingScreen({
    super.key,
    this.isCancelMode = false,
    this.bookingId,
  });

  @override
  State<RescheduleBookingScreen> createState() =>
      _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen> {
  String? _selectedReason;
  bool _isConfirmed = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _booking;
  List<String>? _policyRules;
  bool _policyLoading = true;

  final List<String> _reasons = [
    'Personal Reason',
    'Weather Conditions',
    'Health Issues',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooking();
      _loadPolicy();
    });
  }

  Future<void> _loadPolicy() async {
    final type = widget.isCancelMode
        ? 'cancellation-policy'
        : 'booking-policy';
    try {
      final policy = await ActivApiClient.instance.getPolicy(type);
      final body = policy['body']?.toString() ?? '';
      final rules = body
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((sentence) => sentence.trim())
          .where((sentence) => sentence.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _policyRules = rules.isEmpty ? null : rules;
        _policyLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
        _policyRules = null;
        _policyLoading = false;
      });
      }
    }
  }

  Future<void> _loadBooking() async {
    final bookingId = widget.bookingId;
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
      if (!mounted) return;
      setState(() => _booking = booking);
    } on ActivApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _slot =>
      (_booking?['slot'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _facility =>
      (_slot['facility'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _venue =>
      (_facility['venue'] as Map<String, dynamic>?) ?? {};

  String _formatTime(String? iso) {
    final time = DateTime.tryParse(iso ?? '');
    return time == null ? '' : DateFormat('h:mm a').format(time.toLocal());
  }

  int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  Future<void> _handleContinue() async {
    if (widget.isCancelMode) {
      await _submitCancellation();
    } else {
      final venueId = _venue['id']?.toString();
      final facilityName = _facility['name']?.toString() ?? 'Activity';
      final start = DateTime.tryParse(_booking?['startsAt']?.toString() ?? '');
      final end = DateTime.tryParse(_slot['endsAt']?.toString() ?? '');
      final current = RescheduleSummary(
        venue: _venue['name']?.toString() ?? 'ACTIV Venue',
        date: start == null
            ? ''
            : DateFormat('EEEE, dd MMMM yyyy').format(start.toLocal()),
        court: facilityName,
        time: start == null
            ? ''
            : '${DateFormat('h:mm a').format(start.toLocal())} - '
                '${end == null ? '' : DateFormat('h:mm a').format(end.toLocal())}',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookYourSlotScreen(
            isRescheduling: true,
            bookingId: widget.bookingId,
            venueId: venueId,
            currentReschedule: current,
            requiredPricePaise:
                _toInt(_slot['pricePaise']) ?? _toInt(_booking?['totalPaise']),
          ),
        ),
      );
    }
  }

  Future<void> _submitCancellation() async {
    final bookingId = widget.bookingId;
    if (bookingId == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ActivApiClient.instance.cancelBooking(
        bookingId,
        reason: _selectedReason,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.cancellationSummary,
        arguments: {
          'bookingId': bookingId,
          'result': result,
          'paidAmount': _booking?['totalPaise'],
          'startsAt': _booking?['startsAt'],
        },
      );
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(
          title: widget.isCancelMode ? 'Cancel My Booking' : 'Reschedule Booking',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking;
    final venueName = _venue['name']?.toString() ?? 'ACTIV Venue';
    final facilityName = _facility['name']?.toString() ?? 'Activity';
    final cityCode = _venue['cityCode']?.toString() ?? '';
    final slotTime =
        '${_formatTime(booking?['startsAt']?.toString())} - ${_formatTime(_slot['endsAt']?.toString())}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: widget.isCancelMode ? 'Cancel My Booking' : 'Reschedule Booking',
      ),
      body: SafeArea(
        child: booking == null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AppText.small(
                    _error ?? 'Booking details are unavailable.',
                    color: AppColors.grey99,
                    fontSize: 16,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VenueSummaryCard(
                      name: venueName,
                      sport: facilityName,
                      location: cityCode,
                    ),
                    const SizedBox(height: 32),
                    _buildBookingSummaryCard(venueName, facilityName, slotTime),
                    const SizedBox(height: 40),
                    _buildReschedulingPolicy(),
                    const SizedBox(height: 40),
                    SubSectionHeader(
                      title: widget.isCancelMode
                          ? 'Reason of Cancellation'
                          : 'Reason of Rescheduling',
                    ),
                    const SizedBox(height: 16),
                    _buildReasonDropdown(),
                    const SizedBox(height: 40),
                    _buildConfirmationCheckbox(),
                    const SizedBox(height: 40),
                    AppButton(
                      title: widget.isCancelMode ? 'Continue' : 'Select New Slot',
                      onTap: (_isConfirmed && !_isSubmitting)
                          ? _handleContinue
                          : null,
                      backgroundColor: AppColors.blackColor2,
                      textColor: AppColors.primary,
                      showArrow: true,
                      isDisabled: !_isConfirmed || _isSubmitting,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBookingSummaryCard(
    String venueName,
    String facilityName,
    String slotTime,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.small(
                    'Booking ID',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 4),
                  AppText.bold(
                    _booking?['publicCode']?.toString() ?? '',
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText.small(
                    'Sport',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 4),
                  AppText.bold(
                    facilityName,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ],
              ),
            ],
          ),
          const AppDivider(verticalPadding: 16),
          _buildCourtRow(venueName, slotTime, ''),
        ],
      ),
    );
  }

  Widget _buildCourtRow(String courtName, String details, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.medium(
                courtName,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              const SizedBox(height: 4),
              AppText.small(details, color: AppColors.grey99, fontSize: 14),
            ],
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(width: 8),
          AppText.bold(time, color: AppColors.textPrimary, fontSize: 16),
        ],
      ],
    );
  }

  Widget _buildReschedulingPolicy() {
    final rules = _policyLoading
        ? const <String>['Loading policy...']
        : (_policyRules ?? const <String>['Policy is not available right now.']);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: VenueExpandableSection(
        title: widget.isCancelMode
            ? 'Cancellation Policy'
            : 'Rescheduling Policy',
        iconAsset: AppAssets.venueRules,
        child: VenueRulesSection(rules: rules),
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return GestureDetector(
      onTap: () async {
        final result = await showAppSelectionBottomSheet(
          context: context,
          title: widget.isCancelMode
              ? 'Reason of Cancellation'
              : 'Reason of Rescheduling',
          options: _reasons,
          initialSelection: _selectedReason ?? '',
          otherOptionText: 'Others',
        );
        if (result != null) {
          setState(() {
            _selectedReason = result;
          });
        }
      },
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderRadius: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText.small(
                _selectedReason?.isNotEmpty == true
                    ? _selectedReason!
                    : 'Select Reason',
                color: _selectedReason?.isNotEmpty == true
                    ? Colors.white
                    : AppColors.greyBorder,
                fontSize: 16,
              ),
            ),
            const AppSvg(
              AppAssets.downArrow,
              color: AppColors.grey85,
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isConfirmed = !_isConfirmed;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppSvg(
              _isConfirmed ? AppAssets.checkBox : AppAssets.checkBox2,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText.small(
              'I confirm that I have reviewed the ${widget.isCancelMode ? 'Cancellation' : 'Rescheduling'} Policy and accept all applicable terms and conditions.',
              color: AppColors.grey99,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
