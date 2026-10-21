import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/widgets/fields/app_search_bar.dart';
import 'package:activ_user_app/shared/widgets/navigation/custom_bottom_nav_bar.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/sport_filter_list.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/active_filter_chips.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/venue_results_sliver_list.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/venue_search_header_delegate.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/sticky_filter_delegate.dart';

class VenueSearchScreen extends StatefulWidget {
  final String? initialSport;
  final String? cityCode;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? locationLabel;

  const VenueSearchScreen({
    super.key,
    this.initialSport,
    this.cityCode,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.locationLabel,
  });

  @override
  State<VenueSearchScreen> createState() => _VenueSearchScreenState();
}

class _VenueSearchScreenState extends State<VenueSearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  late ScrollController _scrollController;
  bool _isBottomNavVisible = true;

  late List<Map<String, dynamic>> _allVenues;
  bool _isLoading = true;
  String? _error;

  List<String> _activeFilters = [];

  String _searchQuery = '';

  int _selectedSportIndex = 0;
  List<Map<String, dynamic>> _sports = [
    {'name': 'All Sports', 'sportCode': null, 'icon': null},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final isScrollingDown =
          _scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
      final isScrollingUp =
          _scrollController.position.userScrollDirection ==
          ScrollDirection.forward;

      // Only hide the bottom nav after the header has collapsed (threshold ~150)
      if (isScrollingDown && _scrollController.offset > 150) {
        if (_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = false;
          });
        }
      } else if (isScrollingUp) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
      }
    });

    _allVenues = [];
    _loadVenues(refreshSports: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadVenues({required bool refreshSports}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var sports = _sports;
      var selectedIndex = _selectedSportIndex;
      if (refreshSports) {
        final activities = await ActivApiClient.instance.getActivities();
        final items = (activities['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        sports = <Map<String, dynamic>>[
          {'name': 'All Sports', 'sportCode': null, 'icon': null},
          for (final a in items)
            {
              'name': a['name']?.toString() ?? '',
              'sportCode': a['sportCode']?.toString(),
              'id': a['id']?.toString(),
              'icon': a['sportCode'] == null
                  ? null
                  : iconForSport(a['sportCode'].toString()),
              'iconUrl': a['iconUrl']?.toString() ?? '',
            },
        ];
        final initial = widget.initialSport;
        if (initial != null) {
          final index = sports.indexWhere(
            (s) =>
                s['name'].toString().toLowerCase() == initial.toLowerCase(),
          );
          selectedIndex = index == -1 ? 0 : index;
        }
      }
      if (selectedIndex >= sports.length) selectedIndex = 0;
      final activityId = sports[selectedIndex]['id']?.toString();
      final result = await ActivApiClient.instance.getVenues(
        activityId: activityId,
        cityCode: widget.cityCode,
        latitude: widget.latitude,
        longitude: widget.longitude,
        radiusKm: widget.radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _sports = sports;
        _selectedSportIndex = selectedIndex;
        _allVenues = (result['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _isLoading = false;
      });
    } on ActivApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load venues.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredVenues {
    final query = _searchQuery.trim().toLowerCase();
    final ratingAbove = _ratingThreshold(_activeFilters);
    final activityType = _activityTypeFilter(_activeFilters);
    final maxDistanceKm = _distanceThreshold(_activeFilters);
    final sort = _sortMode(_activeFilters);

    var results = _allVenues.where((venue) {
      if (query.isNotEmpty) {
        final name = (venue['name'] ?? venue['title'] ?? '')
            .toString()
            .toLowerCase();
        final location = (venue['location'] ?? venue['city'] ?? '')
            .toString()
            .toLowerCase();
        if (!name.contains(query) && !location.contains(query)) return false;
      }
      if (ratingAbove != null) {
        final rating = (venue['rating'] as num?)?.toDouble() ?? 0.0;
        if (rating < ratingAbove) return false;
      }
      if (activityType != null) {
        final type = (venue['type'] ?? venue['category'] ?? '')
            .toString()
            .toLowerCase();
        if (!type.contains(activityType.toLowerCase())) return false;
      }
      if (maxDistanceKm != null) {
        final distance = (venue['distanceKm'] as num?)?.toDouble();
        if (distance != null && distance > maxDistanceKm) return false;
      }
      return true;
    }).toList();

    if (sort == 'price-asc') {
      results.sort(
        (a, b) => ((a['price'] as num?)?.toDouble() ?? 0).compareTo(
          (b['price'] as num?)?.toDouble() ?? 0,
        ),
      );
    } else if (sort == 'price-desc') {
      results.sort(
        (a, b) => ((b['price'] as num?)?.toDouble() ?? 0).compareTo(
          (a['price'] as num?)?.toDouble() ?? 0,
        ),
      );
    } else if (sort == 'rating') {
      results.sort(
        (a, b) => ((b['rating'] as num?)?.toDouble() ?? 0).compareTo(
          (a['rating'] as num?)?.toDouble() ?? 0,
        ),
      );
    } else if (sort == 'popular') {
      results.sort(
        (a, b) => ((b['reviews'] as num?)?.toInt() ?? 0).compareTo(
          (a['reviews'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return results;
  }

  double? _ratingThreshold(List<String> filters) {
    for (final f in filters) {
      final match = RegExp(r'^([0-9.]+) and above$').firstMatch(f);
      if (match != null) return double.tryParse(match.group(1)!);
    }
    return null;
  }

  String? _activityTypeFilter(List<String> filters) {
    const types = {'Single', 'Court', 'Turf', 'Table', 'Cricket Nets'};
    for (final f in filters) {
      if (types.contains(f)) return f;
    }
    return null;
  }

  double? _distanceThreshold(List<String> filters) {
    final match = RegExp(r'^Under ([0-9.]+) km$').firstMatch(filters.join(' '));
    if (match != null) return double.tryParse(match.group(1)!);
    return null;
  }

  String? _sortMode(List<String> filters) {
    if (filters.contains('Price Low to High')) return 'price-asc';
    if (filters.contains('Price High to Low')) return 'price-desc';
    if (filters.contains('Rating High to Low')) return 'rating';
    if (filters.contains('Popular')) return 'popular';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSportName = _sports[_selectedSportIndex]['name'];
    final selectedSportIcon = _sports[_selectedSportIndex]['icon'];
    final selectedSportIconUrl =
        _sports[_selectedSportIndex]['iconUrl']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: _isBottomNavVisible
          ? CustomBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.dashboard,
                    (route) => false,
                    arguments: {'initialIndex': index},
                  );
                }
              },
            )
          : const SizedBox.shrink(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Collapsible Header (Search + Categories)
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: VenueSearchHeaderDelegate(
                  statusBarHeight: MediaQuery.of(context).padding.top,
                  expandedHeight: 170.0,
                  collapsedHeight: 60.0,
                  selectedSportName: selectedSportName,
                  selectedSportIcon: selectedSportIcon,
                  selectedSportIconUrl: selectedSportIconUrl,
                  onSearchTap: () {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                    _searchFocusNode.requestFocus();
                  },
                  searchBar: AppSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    hintText: 'Search for Gym',
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  sportFilterList: SportFilterList(
                    sports: _sports,
                    selectedIndex: _selectedSportIndex,
                    onSportSelected: (index) {
                      setState(() {
                        _selectedSportIndex = index;
                      });
                      _loadVenues(refreshSports: false);
                    },
                  ),
                ),
              ),

              // Space that scrolls away
              SliverToBoxAdapter(
                child: Container(
                  height: 24.0, // Adds up to 32 with the 8.0 padding below
                  color: AppColors.background,
                ),
              ),

              // Sticky Filters Row
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyFilterDelegate(
                  height: 56.0, // Reduced height to exactly fit the chips row
                  child: Container(
                    color: AppColors.background,
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: ActiveFilterChips(
                        activeFilters: _activeFilters,
                        onClearFilter: (filter) {
                          setState(() {
                            _activeFilters.remove(filter);
                          });
                        },
                        onFilterButtonPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.venueFilter,
                          );
                          if (result != null && result is List<String>) {
                            setState(() {
                              _activeFilters = result;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text('Unable to load venues. Pull to retry.'),
                  ),
                )
              else if (_filteredVenues.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.locationLabel == null
                            ? 'No venues found.'
                            : 'No venues available near ${widget.locationLabel} yet.\nTry changing location or explore available cities.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.grey99),
                      ),
                    ),
                  ),
                )
              else
                // Venue Cards
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  sliver: VenueResultsSliverList(venues: _filteredVenues),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
