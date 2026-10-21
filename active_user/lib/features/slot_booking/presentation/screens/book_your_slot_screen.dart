import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/slot_booking/presentation/controllers/book_slot_controller.dart';
import 'package:activ_user_app/features/slot_booking/data/models/booking_models.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/date_filter_list.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/booking_activity_selector.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/booking_duration_selector.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/slot_period_tabs.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/time_slot_grid.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/court_selection_list.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/booking_user_details_card.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/player_count_selector.dart';
import 'package:activ_user_app/features/review_booking/presentation/screens/review_booking_screen.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/confirm_reschedule_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/success_bottom_sheet.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class BookYourSlotScreen extends ConsumerStatefulWidget {
  final String? initialActivity;
  final String? venueId;
  final bool isRescheduling;
  final String? bookingId;
  final RescheduleSummary? currentReschedule;
  final int? requiredPricePaise;
  const BookYourSlotScreen({
    super.key,
    this.initialActivity,
    this.venueId,
    this.isRescheduling = false,
    this.bookingId,
    this.currentReschedule,
    this.requiredPricePaise,
  });

  @override
  ConsumerState<BookYourSlotScreen> createState() => _BookYourSlotScreenState();
}

class _BookYourSlotScreenState extends ConsumerState<BookYourSlotScreen> {
  String _selectedPeriod = 'Morning';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialActivity != null) {
        ref
            .read(bookSlotControllerProvider.notifier)
            .selectActivity(widget.initialActivity!);
      }
      if (widget.venueId != null) {
        ref.read(bookSlotControllerProvider.notifier).loadAvailability(widget.venueId!, DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookSlotControllerProvider);
    final controller = ref.read(bookSlotControllerProvider.notifier);

    final requiredPricePaise =
        widget.isRescheduling ? widget.requiredPricePaise : null;
    final availableSlots = controller.getAvailableStartTimes(
      requiredPricePaise: requiredPricePaise,
    );
    final availableCourts = controller.getAvailableCourtsForSelectedTime(
      requiredPricePaise: requiredPricePaise,
    );

    // Bottom bar time string
    String bottomTimeString = '';
    if (state.selectedStartTime != null) {
      final end = state.selectedStartTime!.add(
        Duration(minutes: state.selectedDurationMinutes),
      );
      bottomTimeString =
          '${DateFormat('h').format(state.selectedStartTime!)} - ${DateFormat('h a').format(end)}';
    }

    // Filter slots based on selected period
    int startHour = 0;
    int endHour = 11; // Morning: midnight - 11:59 AM
    if (_selectedPeriod == 'Noon') {
      startHour = 12;
      endHour = 15; // Noon: 12 PM - 3:59 PM
    } else if (_selectedPeriod == 'Evening') {
      startHour = 16;
      endHour = 19; // Evening: 4 PM - 7:59 PM
    } else if (_selectedPeriod == 'Night') {
      startHour = 20;
      endHour = 23; // Night: 8 PM - 11:59 PM
    }

    final List<DateTime> periodSlots =
        controller.getSlotTimesForPeriod(
          startHour: startHour,
          endHour: endHour,
          requiredPricePaise: requiredPricePaise,
        );

    if (state.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (state.errorMessage != null) return Scaffold(appBar: const AppHeader(title: 'Book Your Slot'), body: Center(child: AppText(state.errorMessage!, color: Colors.redAccent, textAlign: TextAlign.center)));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: widget.isRescheduling ? 'Select New Slot' : 'Book Your Slot',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateFilterList(
                    selectedDate: state.selectedDate,
                    onDateSelected: controller.selectDate,
                  ),

                  if (widget.isRescheduling) ...[
                    const SizedBox(height: 32),
                    AppText.bold(
                      'Select an available slot',
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                    const SizedBox(height: 8),
                    AppText.small(
                      'Choose an available time slot for rescheduling.',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const SizedBox(height: 40),
                    BookingActivitySelector(
                      activities: controller.activityNames,
                      selectedActivity: state.selectedActivity,
                      onActivitySelected: controller.selectActivity,
                    ),

                    const AppDivider(),

                    BookingDurationSelector(
                      durations: controller.availableDurations.isEmpty
                          ? [state.selectedDurationMinutes]
                          : controller.availableDurations,
                      selectedDuration: state.selectedDurationMinutes,
                      onDurationSelected: controller.selectDuration,
                    ),

                    const SizedBox(height: 16),
                  ],

                  SlotPeriodTabs(
                    selectedPeriod: _selectedPeriod,
                    onPeriodSelected: (p) =>
                        setState(() => _selectedPeriod = p),
                  ),

                  const SizedBox(height: 24),
                  TimeSlotGrid(
                    availableSlots: availableSlots,
                    allSlots: periodSlots,
                    selectedSlot: state.selectedStartTime,
                    durationMinutes: state.selectedDurationMinutes,
                    requiredPricePaise: requiredPricePaise,
                    onSlotSelected: (slot) {
                        controller.selectStartTime(slot);
                        if (widget.isRescheduling) {
                          final courts = controller.getAvailableCourtsForSelectedTime(
                            requiredPricePaise: requiredPricePaise,
                          );
                          if (courts.isNotEmpty) {
                            controller.selectCourt(courts.first.id);
                          }
                        }
                      },
                  ),

                  if (!widget.isRescheduling) ...[
                    CourtSelectionList(
                      availableCourts: availableCourts,
                      selectedCourtIds: state.selectedCourtIds,
                      onCourtSelected: controller.selectCourt,
                    ),
                    const AppDivider(),
                    const BookingUserDetailsCard(),
                    const SizedBox(height: 40),
                    PlayerCountSelector(
                      selectedCount: state.playerCount,
                      onCountSelected: controller.updatePlayerCount,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(
                      height: 24,
                    ), // Extra padding at bottom for reschedule
                  ],
                ],
              ),
            ),
          ),

          // Bottom Summary Bar
          AppBottomActionRow(
            title: widget.isRescheduling
                ? (state.selectedStartTime != null ? 'Slot Selected' : 'Select a Slot')
                : '${state.selectedCourtIds.length} Court${state.selectedCourtIds.length > 1 ? 's' : ''} Selected',
            subtitle: bottomTimeString.isNotEmpty ? bottomTimeString : null,
            actionTitle: 'Continue',
            onActionTap:
                (widget.isRescheduling
                    ? state.selectedStartTime != null
                    : state.selectedCourtIds.isNotEmpty)
                ? () async {
                    if (widget.isRescheduling) {
                      // Handle reschedule continuation
                      final selectedTime = state.selectedStartTime;
                      final slotId = controller.selectedSlotId;
                      if (widget.bookingId == null ||
                          selectedTime == null ||
                          slotId == null) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking or slot information is missing.')));
                        return;
                      }
                      final courtName = _currentCourtName(availableCourts, slotId);
                      final end = selectedTime.add(
                        Duration(minutes: state.selectedDurationMinutes),
                      );
                      final neu = RescheduleSummary(
                        venue: controller.venueName ?? 'ACTIV Venue',
                        date: DateFormat('EEEE, dd MMMM yyyy').format(selectedTime),
                        court: courtName,
                        time: '${DateFormat('h:mm a').format(selectedTime)} - ${DateFormat('h:mm a').format(end)}',
                      );
                      final confirmed = await showConfirmRescheduleBottomSheet(
                        context,
                        current: widget.currentReschedule ??
                            RescheduleSummary(
                              venue: controller.venueName ?? 'ACTIV Venue',
                              date: DateFormat('EEEE, dd MMMM yyyy').format(selectedTime),
                              court: courtName,
                              time: 'Currently booked slot',
                            ),
                        neu: neu,
                      );
                      if (confirmed == true) {
                        try {
                          await ActivApiClient.instance.rescheduleBooking(widget.bookingId!, slotId);
                        } on ActivApiException catch (error) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                          return;
                        }
                        if (context.mounted) {
                          showSuccessBottomSheet(
                            context: context,
                            title: 'Reschedule Successful',
                            subtitle: 'Your Court is reserved. Get ready to\nplay your best game yet.',
                            topPillText: 'Successful',
                            primaryButtonText: 'View Booking Details',
                            onPrimaryButtonTap: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                              Navigator.pushNamed(
                                context,
                                AppRoutes.bookingDetails,
                                arguments: {
                                  'status': 'rescheduled',
                                  'bookingId': widget.bookingId,
                                },
                              );
                            },
                            secondaryButtonText: 'Back to Home',
                            onSecondaryButtonTap: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          );
                        }
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReviewBookingScreen(),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _currentCourtName(List<CourtModel> courts, String slotId) {
    for (final court in courts) {
      if (court.slotId == slotId) return court.name;
    }
    return 'Court';
  }
}

