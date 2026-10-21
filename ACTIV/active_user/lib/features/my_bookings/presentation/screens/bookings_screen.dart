import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/my_bookings/presentation/widgets/booking_card.dart';
import 'package:activ_user_app/features/my_bookings/presentation/widgets/booking_tab_bar.dart';
import 'package:activ_user_app/features/my_bookings/presentation/shimmer/bookings_shimmer.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;
  final Set<int> _loadedTabs = {};
  final Set<int> _loadingTabs = {};
  final Map<int, String?> _tabErrors = {};

  final List<Map<String, dynamic>> _upcomingBookings = [];

  final List<Map<String, dynamic>> _completedBookings = [];

  final List<Map<String, dynamic>> _cancelledBookings = [];

  @override
  void initState() {
    super.initState();
    _loadTab(_selectedTab);
  }

  Future<void> _loadTab(int tab, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        (_loadedTabs.contains(tab) || _loadingTabs.contains(tab))) {
      return;
    }
    setState(() {
      _loadingTabs.add(tab);
      _tabErrors[tab] = null;
    });
    try {
      final result = await ActivApiClient.instance.getBookings(
        status: _statusForTab(tab),
      );
      if (!mounted) return;
      _listForTab(tab)
        ..clear()
        ..addAll(_mapBookings(result['items']));
      _loadedTabs.add(tab);
    } on ActivApiException catch (error) {
      if (mounted) _tabErrors[tab] = error.message;
    } finally {
      if (mounted) {
        setState(() {
          _loadingTabs.remove(tab);
        });
      }
    }
  }

  String _statusForTab(int tab) => switch (tab) {
        0 => 'CONFIRMED',
        1 => 'COMPLETED',
        _ => 'CANCELLED',
      };

  List<Map<String, dynamic>> _listForTab(int tab) => switch (tab) {
        0 => _upcomingBookings,
        1 => _completedBookings,
        _ => _cancelledBookings,
      };

  List<Map<String, dynamic>> _mapBookings(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map<String, dynamic>>().map((booking) {
      final slot = booking['slot'] as Map<String, dynamic>? ?? {};
      final facility = slot['facility'] as Map<String, dynamic>? ?? {};
      final venue = facility['venue'] as Map<String, dynamic>? ?? {};
      final startsAt = DateTime.tryParse('${booking['startsAt']}');
      final endsAt = DateTime.tryParse('${slot['endsAt']}');
      return {
        'id': booking['id']?.toString(),
        'title': venue['name'] ?? 'ACTIV Venue',
        'sport': facility['name'] ?? 'Activity',
        'location': venue['cityCode'] ?? '',
        'date': startsAt == null
            ? ''
            : DateFormat('dd MMM').format(startsAt.toLocal()),
        'time': startsAt == null || endsAt == null
            ? ''
            : '${DateFormat('h:mm a').format(startsAt.toLocal())} - ${DateFormat('h:mm a').format(endsAt.toLocal())}',
        'status': '${booking['status']}'.replaceAll('_', ' '),
      };
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await _loadTab(_selectedTab, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _listForTab(_selectedTab);
    final isLoading = _loadingTabs.contains(_selectedTab);
    final error = _tabErrors[_selectedTab];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'My Bookings'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Tab Bar
              BookingTabBar(
                selectedIndex: _selectedTab,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                  _loadTab(index);
                },
              ),
              const SizedBox(height: 32),

              // Bookings Feed
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _handleRefresh,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading
                        ? const BookingsShimmer(key: ValueKey('shimmer'))
                        : currentList.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: AppText.bold(
                                  error ?? 'Your Next Activity Starts Here',
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: AppText.small(
                                  'Discover sports, fitness & wellness activities near you and book your first one.',
                                  color: AppColors.grey99,
                                  fontSize: 16,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 40),

                              AppButton(
                                title: 'Explore ACTIV',
                                backgroundColor: AppColors.blackColor2,
                                textColor: AppColors.primary,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.dashboard,
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: currentList.length,
                            itemBuilder: (context, index) {
                              final booking = currentList[index];
                              return BookingCard(
                                title: booking['title'],
                                sport: booking['sport'],
                                location: booking['location'],
                                date: booking['date'],
                                time: booking['time'],
                                status: booking['status'],
                                bookingId: booking['id'],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
