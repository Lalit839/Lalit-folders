import 'dart:async';
import 'dart:convert';

import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/models/selected_location.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/core/widgets/fields/app_search_bar.dart';
import 'package:activ_user_app/core/widgets/common/section_header.dart';
import 'package:activ_user_app/core/widgets/cards/venue_card.dart';
import 'package:activ_user_app/features/home/presentation/widgets/home_header.dart';
import 'package:activ_user_app/features/home/presentation/widgets/play_every_moment_banner.dart';
import 'package:activ_user_app/features/home/presentation/widgets/sport_category_list.dart';
import 'package:activ_user_app/features/home/presentation/widgets/promo_banner_card.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/home_shimmer.dart';
import 'package:activ_user_app/features/home/presentation/shimmer/venue_card_shimmer.dart';
import 'package:activ_user_app/features/home/presentation/widgets/venue_stack_swiper.dart';
import 'package:activ_user_app/features/home/presentation/widgets/swipe_venue_card.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/features/home/presentation/widgets/all_sports_bottom_sheet.dart';
import 'package:activ_user_app/features/home/presentation/widgets/upcoming_booking_reminder_card.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _locationName = 'Set location';
  SelectedLocation? _selectedLocation;
  bool _isLoading = false;
  bool _isVenueLoading = true;
  bool _venueLoadFailed = false;
  bool _showUpcomingBooking = true;
  Map<String, dynamic>? _upcomingBooking;
  double? _latitude;
  double? _longitude;

  final List<Map<String, String>> _categories = List<Map<String, String>>.of(
    mergeAssetSportCategories(const <Map<String, String>>[]),
  );
  final List<Map<String, String>> _nearbySportCategories = [];

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Reserve Your\nNext Game Instantly',
      'image': AppAssets.footballTurf,
      'gradientColors': [
        AppColors.primary.withValues(alpha: 0.8),
        const Color(0xFF6A1B9A),
      ],
    },
    {
      'title': 'Get 20% Off\nOn First Booking',
      'image': AppAssets.badminton,
      'gradientColors': [const Color(0xFF00C853), const Color(0xFF009688)],
    },
  ];

  final List<Map<String, dynamic>> _venuesAround = [];

  final List<Map<String, dynamic>> _trendingVenues = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateSelectedLocation();
      _hydrateCachedCatalog();
      _loadCatalog();
    });
  }

  Future<void> _loadCatalog() async {
    if (mounted && _venuesAround.isEmpty) {
      setState(() {
        _isVenueLoading = true;
        _venueLoadFailed = false;
      });
    }

    final activitiesFuture = _loadActivities();
    final nearbyActivitiesFuture = _loadNearbyActivities();
    final venuesFuture = _loadVenues();

    await venuesFuture;
    unawaited(activitiesFuture);
    unawaited(nearbyActivitiesFuture);

    unawaited(_loadUpcomingBooking());
  }

  void _hydrateSelectedLocation() {
    final location = SharedPrefService.selectedLocation;
    if (location == null) return;
    _selectedLocation = location;
    _locationName = location.headerLabel;
    _latitude = location.latitude;
    _longitude = location.longitude;
  }

  void _hydrateCachedCatalog() {
    final cachedActivities = _decodeCachedList(
      SharedPrefService.homeActivitiesCache,
    );
    final cachedVenues = _decodeCachedList(SharedPrefService.homeVenuesCache);

    if (cachedActivities.isEmpty && cachedVenues.isEmpty) return;
    if (!mounted) return;

    setState(() {
      if (cachedActivities.isNotEmpty) _applyActivities(cachedActivities);
      if (cachedVenues.isNotEmpty) {
        _applyVenues(cachedVenues);
        _isVenueLoading = false;
      }
    });
  }

  Future<void> _loadActivities() async {
    try {
      final result = await ActivApiClient.instance.getActivities();
      final activities = result['items'] as List? ?? const [];
      unawaited(
        SharedPrefService.setHomeActivitiesCache(jsonEncode(activities)),
      );

      if (!mounted) return;
      setState(() {
        _applyActivities(activities);
      });
    } catch (_) {
      // Keep the default asset categories or cached categories visible.
    }
  }

  Future<void> _loadNearbyActivities() async {
    try {
      final result = await ActivApiClient.instance.getNearbyActivities(
        cityCode: _activeCityCode,
        latitude: _latitude,
        longitude: _longitude,
        radiusKm: _hasSelectedCoordinates ? 30 : null,
        limit: 20,
      );
      final activities = result['items'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _nearbySportCategories
          ..clear()
          ..addAll(
            activities.whereType<Map<String, dynamic>>().map((activity) {
              final sportCode = activity['sportCode']?.toString() ?? '';
              return {
                'label': activity['name']?.toString() ?? '',
                'sportCode': sportCode,
                'iconPath': iconForSport(sportCode),
                'iconUrl': activity['iconUrl']?.toString() ?? '',
              };
            }).where((activity) => activity['label']!.isNotEmpty),
          );
      });
    } catch (_) {
      // Keep full catalogue fallback visible if nearby sports cannot load.
    }
  }

  Future<void> _loadVenues() async {
    try {
      final result = await ActivApiClient.instance.getVenues(
        cityCode: _activeCityCode,
        latitude: _latitude,
        longitude: _longitude,
        radiusKm: _hasSelectedCoordinates ? 30 : null,
        limit: 20,
      );
      final venues = result['items'] as List? ?? const [];
      unawaited(SharedPrefService.setHomeVenuesCache(jsonEncode(venues)));

      if (!mounted) return;
      setState(() {
        _applyVenues(venues);
        _isVenueLoading = false;
        _venueLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVenueLoading = false;
        _venueLoadFailed = _venuesAround.isEmpty;
      });
    }
  }

  List<dynamic> _decodeCachedList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }

  void _applyActivities(List<dynamic> activities) {
    final activityCategories = activities.whereType<Map<String, dynamic>>().map(
      (a) => {
        'label': a['name']?.toString() ?? '',
        'sportCode': a['sportCode']?.toString() ?? '',
        'iconPath': iconForSport(a['sportCode']?.toString()),
        'iconUrl': '',
      },
    );
    _categories
      ..clear()
      ..addAll(
        List<Map<String, String>>.of(
          mergeAssetSportCategories(activityCategories),
        ),
      );
  }

  void _applyVenues(List<dynamic> venues) {
    final mapped = venues
        .whereType<Map<String, dynamic>>()
        .map(_mapVenue)
        .toList();
    _venuesAround
      ..clear()
      ..addAll(mapped.take(5));
    _trendingVenues
      ..clear()
      ..addAll(mapped.length > 1 ? mapped.skip(1) : mapped);
  }

  Map<String, dynamic> _mapVenue(Map<String, dynamic> v) {
    final images =
        (v['imageUrls'] as List?)?.map<String>((e) => e.toString()).toList() ??
        const <String>[];
    final rating = num.tryParse(v['rating']?.toString() ?? '') ?? 0;
    final reviews =
        int.tryParse((v['reviewCount'] ?? v['reviews'] ?? 0).toString()) ?? 0;
    return <String, dynamic>{
      'id': v['id'],
      'title': v['name'] ?? v['title'] ?? 'ACTIV Venue',
      'imagePath': images.isNotEmpty
          ? images.first
          : (v['imagePath'] ?? v['image'] ?? '').toString(),
      'imageUrls': images,
      'distance': (v['distance'] ?? v['distanceKm'] ?? '').toString(),
      'location': (v['location'] ?? v['city'] ?? v['cityCode'] ?? v['address'] ?? '')
          .toString(),
      'discount': v['discount']?.toString() ?? '',
      'rating': rating.toDouble(),
      'reviews': reviews,
      'isAvailable': v['isAvailable'] ?? true,
      'activities': v['activities'] ?? const [],
    };
  }

  bool get _hasSelectedCoordinates => _latitude != null && _longitude != null;

  String? get _activeCityCode => _selectedLocation?.cityCode;

  String get _emptyLocationName =>
      _selectedLocation?.city ?? _selectedLocation?.locality ?? _locationName;

  Future<void> _loadUpcomingBooking() async {
    try {
      final bookings = await ActivApiClient.instance.getBookings(limit: 10);
      final items = (bookings['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>();
      final now = DateTime.now().toUtc();
      Map<String, dynamic>? next;
      for (final booking in items) {
        final status = booking['status']?.toString().toUpperCase() ?? '';
        final startsAt = DateTime.tryParse(
          booking['slot']?['startsAt']?.toString() ?? '',
        );
        if (status == 'CONFIRMED' &&
            startsAt != null &&
            startsAt.toUtc().isAfter(now)) {
          if (next == null ||
              startsAt.isBefore(
                DateTime.parse(next['slot']!['startsAt'].toString()),
              )) {
            next = booking;
          }
        }
      }
      if (mounted) {
        setState(() {
          _upcomingBooking = next;
          _showUpcomingBooking = next != null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _showUpcomingBooking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _hydrateSelectedLocation();
  }

  // Simulates an API loading state of 1.5 seconds when pulling to refresh or selecting manual location
  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Navigate to SetLocationScreen
  void _showManualLocationSelector() async {
    final result = await Navigator.pushNamed(context, AppRoutes.setLocation);
    final selection = _parseLocationSelection(result);
    if (selection != null) {
      await SharedPrefService.setSelectedLocation(selection);
      setState(() {
        _selectedLocation = selection;
        _locationName = selection.headerLabel;
        _latitude = selection.latitude;
        _longitude = selection.longitude;
        _isLoading = true;
      });
      unawaited(_loadNearbyActivities());
      unawaited(_loadVenues());
      _simulateLoading();
    }
  }

  SelectedLocation? _parseLocationSelection(Object? result) {
    if (result is Map) {
      try {
        return SelectedLocation.fromJson(Map<String, dynamic>.from(result));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> _venueSearchArguments([String? selectedSport]) {
    return {
      if (selectedSport != null && selectedSport.isNotEmpty)
        'selectedSport': selectedSport,
      'cityCode': _activeCityCode,
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      if (_hasSelectedCoordinates) 'radiusKm': 30.0,
      'locationLabel': _emptyLocationName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Always show the normal content scroll view in the background
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                setState(() {
                  _isVenueLoading = _venuesAround.isEmpty;
                  _venueLoadFailed = false;
                });
                await _loadCatalog();
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 16.0,
                        ),
                        child: const HomeShimmer(key: ValueKey('shimmer')),
                      )
                    : CustomScrollView(
                        key: const ValueKey('content'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 16.0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // 1. Home Header
                                  HomeHeader(
                                    currentLocation: _locationName,
                                    showUnreadDot: SharedPrefService
                                        .hasUnreadNotifications,
                                    onLocationTap: _showManualLocationSelector,
                                    onNotificationTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        AppRoutes.notifications,
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    onProfileTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.profile,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SearchBarDelegate(
                              routeArguments: _venueSearchArguments(),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 16.0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  // 3. Pick a Sport Section
                                  SportCategoryList(
                                    categories: _nearbySportCategories
                                            .isNotEmpty
                                        ? _nearbySportCategories
                                        : _categories,
                                    onCategoryTap: (index) {
                                      final visibleCategories =
                                          _nearbySportCategories.isNotEmpty
                                          ? _nearbySportCategories
                                          : _categories;
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.venueSearch,
                                        arguments: _venueSearchArguments(
                                          visibleCategories[index]['label'],
                                        ),
                                      );
                                    },
                                    onViewAllTap: () =>
                                        showAllSportsBottomSheet(
                                          context,
                                          _categories,
                                          _venueSearchArguments,
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 4. Promo Banners (Horizontal List)
                                  SizedBox(
                                    height: 74,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _promoBanners.length,
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context, index) {
                                        final banner = _promoBanners[index];
                                        return PromoBannerCard(
                                          title: banner['title'],
                                          image: banner['image'],
                                          gradientColors:
                                              banner['gradientColors'],
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.venueSearch,
                                              arguments:
                                                  _venueSearchArguments(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // 5. Venues Around You
                                  SectionHeader(
                                    title: 'Venues Around You',
                                    showSeeAll: _venuesAround.length > 1,
                                    onSeeAllTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.venueSearch,
                                        arguments: _venueSearchArguments(),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (_venuesAround.isEmpty && _isVenueLoading)
                                    const SizedBox(
                                      height: 344,
                                      child: Center(child: VenueCardShimmer()),
                                    )
                                  else if (_venuesAround.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          AppText(
                                            _venueLoadFailed
                                                ? 'Unable to load venues. Pull to retry.'
                                                : 'No venues available near $_emptyLocationName yet.\nWe are not available here yet. You can explore another location.',
                                            color: AppColors.grey99,
                                            textAlign: TextAlign.center,
                                          ),
                                          if (!_venueLoadFailed) ...[
                                            const SizedBox(height: 16),
                                            GestureDetector(
                                              onTap: _showManualLocationSelector,
                                              child: AppText.bold(
                                                'Change Location',
                                                color: AppColors.primary,
                                                fontSize: 16,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            GestureDetector(
                                              onTap: _showManualLocationSelector,
                                              child: AppText(
                                                'Explore available cities',
                                                color: AppColors.greyBorder,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else if (_venuesAround.length == 1)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 29.0,
                                      ), // match bottom spacing
                                      child: SwipeVenueCard(
                                        venue: _venuesAround[0],
                                        width:
                                            MediaQuery.of(context).size.width -
                                            32,
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.venueDetails,
                                            arguments: {
                                              'venueId': _venuesAround[0]['id'],
                                            },
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      height: 344,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: VenueStackSwiper(
                                          venues: _venuesAround,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 45),

                                  // 6. Trending Venues
                                  if (_trendingVenues.isNotEmpty) ...[
                                    SectionHeader(
                                      title: 'Trending Venues',
                                      onSeeAllTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.venueSearch,
                                          arguments: _venueSearchArguments(),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      children: _trendingVenues.map((venue) {
                                        final images =
                                            (venue['imageUrls'] as List?)
                                                ?.cast<String>() ??
                                            const <String>[];
                                        return VenueCard(
                                          title: venue['title'] ?? '',
                                          imagePath: venue['imagePath'] ?? '',
                                          imageUrls: images,
                                          distance:
                                              venue['distance']?.toString() ??
                                              '',
                                          location:
                                              venue['location']?.toString() ??
                                              '',
                                          discount:
                                              venue['discount']?.toString() ??
                                              '',
                                          rating: (venue['rating'] ?? 0.0)
                                              .toDouble(),
                                          reviews: (venue['reviews'] ?? 0)
                                              .toInt(),
                                          id: venue['id']?.toString(),
                                          isAvailable:
                                              venue['isAvailable'] ?? true,
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.venueDetails,
                                              arguments: {
                                                'venueId': venue['id'],
                                              },
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.venueSearch,
                                          arguments: _venueSearchArguments(),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppText.bold(
                                            'Explore All Venues',
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          AppSvg(
                                            AppAssets.thickArrowRight,
                                            color: AppColors.primary,
                                            height: 24,
                                            width: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const PlayEveryMomentBanner(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Upcoming Booking Floating Card
            if (_showUpcomingBooking && _upcomingBooking != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: UpcomingBookingReminderCard(
                  venueName:
                      _upcomingBooking?['slot']?['facility']?['venue']?['name']
                          ?.toString() ??
                      'Upcoming Booking',
                  startsAt:
                      DateTime.tryParse(
                        _upcomingBooking?['slot']?['startsAt']?.toString() ??
                            '',
                      ) ??
                      DateTime.now().add(const Duration(hours: 1)),
                  onClose: () {
                    setState(() {
                      _showUpcomingBooking = false;
                    });
                  },
                  onViewDetails: () {
                    setState(() {
                      _showUpcomingBooking = false;
                    });
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookingDetails,
                      arguments: {
                        'status':
                            _upcomingBooking?['status']
                                ?.toString()
                                .toLowerCase() ??
                            'upcoming',
                        'bookingId': _upcomingBooking?['id'],
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Map<String, dynamic> routeArguments;

  const _SearchBarDelegate({required this.routeArguments});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Add subtle background color when scrolling to make the transition feel premium.
    final bool isPinned = shrinkOffset > 0 || overlapsContent;

    return Container(
      color: isPinned ? AppColors.background : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: Alignment.center,
      child: AppSearchBar(
        readOnly: true,
        animatedHints: const [
          'Search for badminton venues',
          'Search for cricket turfs',
          'Search for football grounds',
          'Search by venue name',
          'Search for venues near you',
        ],
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.venueSearch,
            arguments: routeArguments,
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 76.0;

  @override
  double get minExtent => 76.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _SearchBarDelegate ||
        oldDelegate.routeArguments != routeArguments;
  }
}
