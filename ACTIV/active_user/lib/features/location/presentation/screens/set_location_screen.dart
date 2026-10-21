import 'dart:async';

import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/models/selected_location.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/services/location_search_service.dart';
import 'package:activ_user_app/core/services/location_service.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/widgets/fields/app_search_bar.dart';
import 'package:activ_user_app/features/home/presentation/widgets/location_permission_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/current_location_card.dart';
import '../widgets/location_list_item.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int _searchVersion = 0;
  bool _isFetchingLocation = false;
  bool _isSearching = false;
  String? _searchError;
  List<PlaceSuggestion> _suggestions = const [];
  List<Map<String, dynamic>> _operatingCities = const [];
  bool _isLoadingCities = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOperatingCities());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOperatingCities() async {
    try {
      final result = await ActivApiClient.instance.getOperatingCities();
      if (!mounted) return;
      setState(() {
        _operatingCities = (result['cities'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _isLoadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_searchPlaces(query));
    });
  }

  Future<void> _searchPlaces(String query) async {
    final version = ++_searchVersion;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final suggestions = await LocationSearchService.instance.searchPlaces(
        query,
      );
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _suggestions = const [];
        _isSearching = false;
        _searchError = 'Unable to search locations';
      });
    }
  }

  Future<void> _selectLocation(SelectedLocation location) async {
    await SharedPrefService.setSelectedLocation(location);
    if (!mounted) return;
    Navigator.pop(context, location.toJson());
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    try {
      final location = await LocationSearchService.instance
          .detailsForSuggestion(suggestion);
      await _selectLocation(location);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select this location')),
      );
    }
  }

  Future<void> _selectOperatingCity(Map<String, dynamic> city) async {
    final latitude = (city['latitude'] as num?)?.toDouble();
    final longitude = (city['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return;
    final cityName = city['city']?.toString() ?? '';
    final state = city['state']?.toString();
    await _selectLocation(
      SelectedLocation(
        displayName: [
          cityName,
          if (state != null && state.isNotEmpty) state,
        ].join(', '),
        city: cityName,
        locality: cityName,
        state: state,
        country: 'India',
        countryCode: 'IN',
        latitude: latitude,
        longitude: longitude,
        cityCode: city['cityCode']?.toString(),
      ),
    );
  }

  void _showPermissionPopup(LocationState state) {
    if (!mounted) return;
    showLocationPermissionBottomSheet(
      context: context,
      state: state,
      onAllowLocationAccess: () async {
        await _handleCurrentLocationTap();
      },
      onEnableGPS: () async {
        await LocationService.openLocationSettings();
      },
      onOpenSettings: () async {
        await LocationService.openAppSettings();
      },
      onSelectManualLocation: () {},
    );
  }

  Future<void> _handleCurrentLocationTap() async {
    setState(() => _isFetchingLocation = true);

    try {
      final isGpsEnabled = await LocationService.isLocationEnabled();
      if (!isGpsEnabled) {
        _showPermissionPopup(LocationState.gpsDisabled);
        return;
      }

      var permission = await LocationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await LocationService.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionPopup(LocationState.permissionDenied);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPopup(LocationState.permissionPermanentlyDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final location = await LocationSearchService.instance.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      await _selectLocation(location);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  bool get _isTyping => _searchController.text.trim().isNotEmpty;

  String _operatingCityTitle(Map<String, dynamic> city) {
    final name = city['city']?.toString() ?? '';
    final state = city['state']?.toString() ?? '';
    return [
      if (name.isNotEmpty) name,
      if (state.isNotEmpty) state,
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Set Location'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search city, area or locality',
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (!_isTyping) ...[
              CurrentLocationCard(
                isLoading: _isFetchingLocation,
                subtitle: _isFetchingLocation ? 'Locating you...' : null,
                onTap: _handleCurrentLocationTap,
              ),
              const SizedBox(height: 40),
              AppText.bold(
                'Cities We Operate In',
                color: AppColors.greyBorder,
              ),
              const SizedBox(height: 24),
              if (_isLoadingCities)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_operatingCities.isEmpty)
                AppText(
                  'No operating cities available right now.',
                  color: AppColors.grey99,
                )
              else
                ..._operatingCities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: LocationListItem(
                      title: _operatingCityTitle(city),
                      onTap: () => _selectOperatingCity(city),
                    ),
                  ),
                ),
            ] else ...[
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: AppText(_searchError!, color: AppColors.grey99),
                )
              else if (_suggestions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppText(
                    'No locations found',
                    color: AppColors.grey99,
                  ),
                )
              else
                ..._suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.yellowColorLight,
                      ),
                      title: AppText.small(
                        suggestion.mainText,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      subtitle: suggestion.secondaryText.isNotEmpty
                          ? AppText(
                              suggestion.secondaryText,
                              color: AppColors.grey99,
                            )
                          : null,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.white,
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
