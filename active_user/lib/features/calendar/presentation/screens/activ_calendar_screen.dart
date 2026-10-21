import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/activ_calendar_day_view.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/activ_calendar_empty_state.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/activ_calendar_week_view.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/consistency_level_card.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/share_activity_bottom_sheet.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/select_week_bottom_sheet.dart';
import 'package:activ_user_app/features/calendar/presentation/widgets/select_date_bottom_sheet.dart';

class ActivCalendarScreen extends StatefulWidget {
  const ActivCalendarScreen({super.key});
  @override
  State<ActivCalendarScreen> createState() => _ActivCalendarScreenState();
}

class _ActivCalendarScreenState extends State<ActivCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isWeekView = true;
  bool _loading = true;
  String? _error;
  List<dynamic> _activities = [];
  final GlobalKey _shareBoundaryKey = GlobalKey();

  @override
  void initState() { 
    super.initState(); 
    _loadCalendar(); 
  }

  Future<void> _loadCalendar() async {
    // For week view, load the whole week. For day view, load the whole month to easily switch days.
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    final from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final to = from.add(const Duration(days: 7));
    
    setState(() { _loading = true; _error = null; });
    try {
      final activities = await ActivApiClient.instance.getCalendar(from, to);
      if (mounted) setState(() { _activities = activities; _loading = false; });
    } on ActivApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  void _showShareBottomSheet() {
    ShareActivityBottomSheet.show(
      context,
      isWeekView: _isWeekView,
      date: _selectedDate,
      contentToCapture: _buildShareContent(),
      activeDaysCount: _calculateConsistencyLevel(),
    );
  }

  Widget _buildShareContent() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    if (_isWeekView) {
      return ActivCalendarWeekView(
        weekStart: startOfWeek,
        activities: _activities.cast<Map<String, dynamic>>(),
        getSportColor: _getSportColor,
        getSportIcon: _getSportIcon,
        onShare: _showShareBottomSheet,
      );
    } else {
      final dayActivities = _activities.where((act) {
        final starts = DateTime.tryParse('${act['startsAt']}')?.toLocal();
        return starts != null &&
            starts.year == _selectedDate.year &&
            starts.month == _selectedDate.month &&
            starts.day == _selectedDate.day;
      }).cast<Map<String, dynamic>>().toList();

      return ActivCalendarDayView(
        activities: dayActivities,
        getSportColor: _getSportColor,
        getSportIcon: _getSportIcon,
      );
    }
  }

  Color _getSportColor(String sportName) {
    switch (sportName.toLowerCase()) {
      case 'swimming':
        return AppColors.skyBlue;
      case 'badminton':
        return AppColors.purpleColor;
      case 'gym':
      case 'yoga':
        return AppColors.greenColorLight;
      case 'football':
      default:
        return AppColors.primary;
    }
  }

  Widget _getSportIcon(String sportName, Color color) {
    String assetPath;
    switch (sportName.toLowerCase()) {
      case 'swimming':
        assetPath = AppAssets.calendarSwimming;
        break;
      case 'badminton':
      case 'tennis':
      case 'pickleball':
      case 'table tennis':
        assetPath = AppAssets.calendarBadminton;
        break;
      case 'gym':
      case 'yoga':
      case 'crossfit':
      case 'zumba':
      case 'dance':
        assetPath = AppAssets.svgGym;
        break;
      case 'football':
      case 'cricket':
      case 'kabaddi':
      case 'basketball':
      case 'volleyball':
      case 'hockey':
      case 'boxing':
        assetPath = AppAssets.calendarFootball;
        break;
      default:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.blackColor2,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(Icons.sports, color: color, size: 12),
        );
    }
    return AppSvg(assetPath, color: color, height: 20, width: 20);
  }

  int _calculateConsistencyLevel() {
    // Count unique days with activities
    final Set<String> activeDates = {};
    for (var act in _activities) {
      final starts = DateTime.tryParse('${act['startsAt']}')?.toLocal();
      if (starts != null) {
        activeDates.add(DateFormat('yyyy-MM-dd').format(starts));
      }
    }
    return activeDates.length;
  }

  Future<void> _pickDate() async {
    DateTime? picked;
    if (_isWeekView) {
      picked = await SelectWeekBottomSheet.show(context, initialDate: _selectedDate);
    } else {
      picked = await SelectDateBottomSheet.show(context, initialDate: _selectedDate);
    }

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked!;
      });
      _loadCalendar();
    }
  }

  String _weekRangeText(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month && start.year == end.year) {
      return '${DateFormat('dd').format(start)} - ${DateFormat('dd MMMM yyyy').format(end)}';
    }
    return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
  }

  Widget _buildAvatar() {
    final photo = SharedPrefService.profilePhotoBase64;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.blackColor2,
      backgroundImage:
          hasPhoto ? MemoryImage(base64Decode(photo)) : null,
      child: hasPhoto
          ? null
          : const Icon(Icons.person, color: AppColors.grey99, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    
    // For Day view, filter activities for selected day
    final dayActivities = _activities.where((act) {
      final starts = DateTime.tryParse('${act['startsAt']}')?.toLocal();
      return starts != null &&
          starts.year == _selectedDate.year &&
          starts.month == _selectedDate.month &&
          starts.day == _selectedDate.day;
    }).cast<Map<String, dynamic>>().toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    AppText.bold(
                      'ACTIV CALENDAR',
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                      const SizedBox(height: 4),
                      AppText.small(
                        'Your Week. Your Move.',
                        color: AppColors.grey99,
                        fontSize: 14,
                      ),
                    ],
                  ),
                  _buildAvatar(),
                ],
              ),
            ),
            
            // Toggle & Date Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date Selector (opens a date picker)
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        AppText.bold(
                          _isWeekView
                              ? _weekRangeText(startOfWeek)
                              : DateFormat('EEEE,\ndd MMMM yyyy').format(_selectedDate),
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                  
                  // Day/Week Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blackColor2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleBtn('Day', !_isWeekView),
                        _buildToggleBtn('Week', _isWeekView),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_loading) 
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null) 
              Expanded(child: Center(child: AppText(_error!, color: AppColors.errorRed, textAlign: TextAlign.center)))
            else 
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // View Content
                      RepaintBoundary(
                        key: _shareBoundaryKey,
                          child: _isWeekView 
                            ? ActivCalendarWeekView(
                                weekStart: startOfWeek,
                                activities: _activities.cast<Map<String, dynamic>>(),
                                getSportColor: _getSportColor,
                                getSportIcon: _getSportIcon,
                                onShare: _showShareBottomSheet,
                              )
                            : (dayActivities.isEmpty && _activities.isEmpty)
                                ? ActivCalendarEmptyState(onShare: _showShareBottomSheet)
                                : ActivCalendarDayView(
                                    activities: dayActivities,
                                    getSportColor: _getSportColor,
                                    getSportIcon: _getSportIcon,
                                  ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Consistency Level Card
                      if (_activities.isNotEmpty)
                        ConsistencyLevelCard(
                          isWeekView: _isWeekView,
                          activeDaysCount: _calculateConsistencyLevel(),
                          dayActivityCount: dayActivities.length,
                          onShare: _showShareBottomSheet,
                        )
                      else
                        const SizedBox(),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekView = label == 'Week';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.yellowDark : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
        ),
        child: AppText.bold(
          label,
          color: isSelected ? AppColors.primary : AppColors.grey99,
          fontSize: 14,
        ),
      ),
    );
  }
}
