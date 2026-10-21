import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/venue/presentation/models/venue_filter_data.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/date_filter_list.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/filter_action_bar.dart';
import 'package:activ_user_app/features/venue/presentation/widgets/filters/options_filter_section.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';

class VenueFilterScreen extends StatefulWidget {
  const VenueFilterScreen({super.key});

  @override
  State<VenueFilterScreen> createState() => _VenueFilterScreenState();
}

class _VenueFilterScreenState extends State<VenueFilterScreen> {
  DateTime? _selectedDate;
  String? _selectedSort;
  String? _selectedDistance;
  String? _selectedRating;
  String? _selectedActivityType;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  void _clearAll() {
    setState(() {
      _selectedDate = DateUtils.dateOnly(DateTime.now());
      _selectedSort = null;
      _selectedDistance = null;
      _selectedRating = null;
      _selectedActivityType = null;
    });
  }

  void _applyFilters() {
    List<String> appliedFilters = [];

    if (_selectedDate != null) {
      final formattedDate = DateFormat(
        'dd MMMM',
      ).format(_selectedDate!).toLowerCase();
      appliedFilters.add(formattedDate);
    }

    if (_selectedSort != null) appliedFilters.add(_selectedSort!);
    if (_selectedDistance != null) appliedFilters.add(_selectedDistance!);
    if (_selectedRating != null) appliedFilters.add(_selectedRating!);
    if (_selectedActivityType != null) {
      appliedFilters.add(_selectedActivityType!);
    }

    Navigator.pop(context, appliedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Discover Venue'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.medium(
                      'Find What Fits You',
                      color: AppColors.yellowColor,
                      fontSize: 20,
                    ),
                    const SizedBox(height: 24),
                    DateFilterList(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    OptionsFilterSection(
                      title: 'Activity Type',
                      options: VenueFilterData.activityTypeOptions,
                      selectedOption: _selectedActivityType,
                      onSelected: (option) {
                        setState(() {
                          _selectedActivityType = option == '' ? null : option;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    Divider(color: AppColors.lightGreyBorder, height: 1),
                    const SizedBox(height: 40),
                    OptionsFilterSection(
                      title: 'Sort By',
                      options: VenueFilterData.sortOptions,
                      selectedOption: _selectedSort,
                      onSelected: (option) {
                        setState(() {
                          _selectedSort = option == '' ? null : option;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    Divider(color: AppColors.lightGreyBorder, height: 1),
                    const SizedBox(height: 40),
                    OptionsFilterSection(
                      title: 'Location',
                      options: VenueFilterData.distanceOptions,
                      selectedOption: _selectedDistance,
                      onSelected: (option) {
                        setState(() {
                          _selectedDistance = option == '' ? null : option;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    Divider(color: AppColors.lightGreyBorder, height: 1),
                    const SizedBox(height: 40),
                    OptionsFilterSection(
                      title: 'Rating',
                      options: VenueFilterData.ratingOptions,
                      selectedOption: _selectedRating,
                      onSelected: (option) {
                        setState(() {
                          _selectedRating = option == '' ? null : option;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            FilterActionBar(onClearAll: _clearAll, onApply: _applyFilters),
          ],
        ),
      ),
    );
  }
}
