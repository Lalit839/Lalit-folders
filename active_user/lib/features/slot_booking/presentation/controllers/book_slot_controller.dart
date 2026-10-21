import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/features/slot_booking/data/models/booking_models.dart';
import 'package:activ_user_app/features/slot_booking/presentation/state/book_slot_state.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/utils/city_label.dart';

class BookSlotController extends Notifier<BookSlotState> {
  int _loadVersion = 0;

  @override
  BookSlotState build() {
    return BookSlotState(selectedDate: DateTime.now());
  }

  String? get venueId => state.venueId;
  String? get venueName => state.venueName;
  String? get venueCity => state.venueCity;
  List<String> get activityNames => state.activityNames;
  DateTime? get selectedDate => state.selectedDate;
  DateTime? get selectedStartTime => state.selectedStartTime;
  int get selectedDurationMinutes => state.selectedDurationMinutes;
  List<String> get selectedCourtIds => state.selectedCourtIds;
  int get playerCount => state.playerCount;

  Future<void> loadAvailability(String venueId, DateTime date) async {
    final loadVersion = ++_loadVersion;
    state = state.copyWith(
      venueId: venueId,
      selectedDate: date,
      isLoading: true,
      clearError: true,
    );
    try {
      final venueFuture = state.venueName == null ? _loadVenue(venueId) : null;
      // Auto-advance to the nearest date that still has future slots (demo data
      // only spans a fixed window, and late in the day "today" has no upcoming slots).
      var target = date;
      var foundFutureSlot = false;
      List<Map<String, dynamic>> parsed = const [];
      for (var attempt = 0; attempt <= 7; attempt++) {
        final result = await ActivApiClient.instance.getAvailability(
          venueId,
          date: _dateKey(target),
        );
        parsed = (result['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_normalizeSlot)
            .toList();
        final hasFutureSlot = parsed.any((item) {
          final startsAt = DateTime.tryParse('${item['startsAt']}');
          return startsAt != null && startsAt.isAfter(DateTime.now().toUtc());
        });
        if (hasFutureSlot) {
          foundFutureSlot = true;
          break;
        }
        target = target.add(const Duration(days: 1));
      }
      if (venueFuture != null) await venueFuture;
      if (loadVersion != _loadVersion) return;
      final duration = _slotDurationMinutes(parsed);
      final slotActivityNames = _activityNamesForSlots(parsed);
      final selectedActivity =
          slotActivityNames.contains(state.selectedActivity)
              ? state.selectedActivity
              : slotActivityNames.isNotEmpty
              ? slotActivityNames.first
              : null;
      state = state.copyWith(
        availability: parsed,
        activityNames: slotActivityNames,
        selectedActivity: selectedActivity,
        clearSelectedActivity: selectedActivity == null,
        selectedDurationMinutes: duration ?? state.selectedDurationMinutes,
        selectedDate: foundFutureSlot ? target : date,
        isLoading: false,
        clearError: true,
      );
    } on ActivApiException catch (error) {
      if (loadVersion != _loadVersion) return;
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadVenue(String venueId) async {
    try {
      final venue = await ActivApiClient.instance.getVenue(venueId);
      final facilities = <String, String>{};
      final facilityActivityIds = <String, String>{};
      for (final raw
          in (venue['facilities'] as List? ?? [])
              .whereType<Map<String, dynamic>>()) {
        final id = raw['id']?.toString();
        final activityId = raw['activityId']?.toString();
        if (id != null && activityId != null) {
          facilities[id] = raw['name']?.toString() ?? 'Court';
          facilityActivityIds[id] = activityId;
        }
      }
      final activityIds = <String, String>{};
      final activityNames = <String>[];
      for (final raw in (venue['activities'] as List? ?? [])) {
        final activity =
            raw is Map<String, dynamic> &&
                raw['activity'] is Map<String, dynamic>
            ? raw['activity'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        final id = activity['id']?.toString();
        final name = activity['name']?.toString();
        if (id != null && name != null) {
          activityIds[name] = id;
          activityNames.add(name);
        }
      }
      state = state.copyWith(
        venueName: venue['name']?.toString(),
        venueCity: venueLocationLabel(venue),
        facilities: facilities,
        facilityActivityIds: facilityActivityIds,
        activityIds: activityIds,
        activityNames: activityNames,
      );
    } on ActivApiException {
      // Venue enrichment is best-effort; availability still renders.
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      clearStartTime: true,
      clearCourtIds: true,
    );
    final venueId = state.venueId;
    if (venueId != null) loadAvailability(venueId, date);
  }

  void selectActivity(String activity) {
    if (!state.activityNames.contains(activity)) return;
    state = state.copyWith(
      selectedActivity: activity,
      clearStartTime: true,
      clearCourtIds: true,
    );
    final durations = availableDurations;
    if (durations.isNotEmpty &&
        !durations.contains(state.selectedDurationMinutes)) {
      state = state.copyWith(selectedDurationMinutes: durations.first);
    }
  }

  void selectDuration(int minutes) {
    state = state.copyWith(
      selectedDurationMinutes: minutes,
      clearStartTime: true,
      clearCourtIds: true,
    );
  }

  void selectStartTime(DateTime startTime) {
    state = state.copyWith(selectedStartTime: startTime, clearCourtIds: true);
    final courts = getAvailableCourtsForSelectedTime();
    if (courts.length == 1) {
      selectCourt(courts.first.id);
    }
  }

  String? get selectedSlotId {
    return state.selectedCourtIds.isNotEmpty
        ? state.selectedCourtIds.first
        : null;
  }

  void selectCourt(String courtId) {
    int players = state.playerCount;
    for (final item in state.availability) {
      if (item['slotId']?.toString() == courtId && courtId.isNotEmpty) {
        final available = _toInt(item['availableQuantity']);
        if (players < 1 || players > available) {
          players = available <= 0 ? 1 : available;
        }
        break;
      }
    }
    state = state.copyWith(selectedCourtIds: [courtId], playerCount: players);
  }

  void updatePlayerCount(int count) {
    if (count > 0) {
      state = state.copyWith(playerCount: count);
    }
  }

  List<DateTime> getAvailableStartTimes({int? requiredPricePaise}) {
    final times = <DateTime>{};
    for (final item in state.availability) {
      final starts = DateTime.tryParse('${item['startsAt']}')?.toLocal();
      if (starts != null &&
          _isBookable(item) &&
          _matchesActivity(item) &&
          _matchesDuration(item) &&
          _matchesPrice(item, requiredPricePaise)) {
        times.add(starts);
      }
    }
    final list = times.toList()..sort();
    return list;
  }

  List<DateTime> getSlotTimesForPeriod({
    required int startHour,
    required int endHour,
    int? requiredPricePaise,
  }) {
    final times = <DateTime>{};
    final nowUtc = DateTime.now().toUtc();
    for (final item in state.availability) {
      final starts = DateTime.tryParse('${item['startsAt']}')?.toLocal();
      if (starts == null) continue;
      final startsUtc = starts.toUtc();
      if (!startsUtc.isAfter(nowUtc)) continue;
      if (!_isBookable(item)) continue;
      if (!_matchesActivity(item)) continue;
      if (!_matchesDuration(item)) continue;
      if (!_matchesPrice(item, requiredPricePaise)) continue;
      final hour = starts.hour;
      if (hour >= startHour && hour <= endHour) times.add(starts);
    }
    final list = times.toList()..sort();
    return list;
  }

  List<CourtModel> getAvailableCourtsForSelectedTime({
    int? requiredPricePaise,
  }) {
    final selectedStartTime = state.selectedStartTime;
    if (selectedStartTime == null) return [];
    final courts = <CourtModel>[];
    for (final item in state.availability) {
      final starts = DateTime.tryParse('${item['startsAt']}')?.toLocal();
      if (starts == null || starts != selectedStartTime || !_isBookable(item)) {
        continue;
      }
      if (!_matchesDuration(item)) continue;
      if (!_matchesActivity(item)) continue;
      if (!_matchesPrice(item, requiredPricePaise)) continue;
      courts.add(_toCourtModel(item));
    }
    return courts;
  }

  int getAvailableCourtsCountForSlot(
    DateTime slotStart, {
    int? requiredPricePaise,
  }) {
    int count = 0;
    for (final item in state.availability) {
      final starts = DateTime.tryParse('${item['startsAt']}')?.toLocal();
      if (starts == null || starts != slotStart || !_isBookable(item)) continue;
      if (!_matchesDuration(item)) continue;
      if (!_matchesActivity(item)) continue;
      if (!_matchesPrice(item, requiredPricePaise)) continue;
      count++;
    }
    return count;
  }

  int getDurationForSlot(DateTime slotStart) {
    for (final item in state.availability) {
      final starts = DateTime.tryParse('${item['startsAt']}')?.toLocal();
      if (starts == null || starts != slotStart) continue;
      final ends = DateTime.tryParse('${item['endsAt']}')?.toLocal();
      if (ends != null) return ends.difference(starts).inMinutes;
    }
    return state.selectedDurationMinutes;
  }

  List<int> get availableDurations {
    final durations = <int>{};
    for (final item in state.availability) {
      if (!_isBookable(item)) continue;
      if (!_matchesActivity(item)) continue;
      final starts = DateTime.tryParse('${item['startsAt']}');
      final ends = DateTime.tryParse('${item['endsAt']}');
      if (starts != null && ends != null) {
        durations.add(ends.difference(starts).inMinutes);
      }
    }
    return durations.toList()..sort();
  }

  bool _matchesActivity(Map<String, dynamic> slot) {
    final selectedActivity = state.selectedActivity;
    if (selectedActivity == null) return true;
    final activityId = state.activityIds[selectedActivity];
    if (activityId == null) return true;
    final facilityActivityId =
        state.facilityActivityIds[slot['facilityId']?.toString()];
    return facilityActivityId == activityId;
  }

  List<String> _activityNamesForSlots(List<Map<String, dynamic>> slots) {
    final activityIdsWithSlots = <String>{};
    for (final slot in slots) {
      if (!_isFutureAvailableSlot(slot)) continue;
      final facilityId = slot['facilityId']?.toString();
      final activityId = state.facilityActivityIds[facilityId];
      if (activityId != null) activityIdsWithSlots.add(activityId);
    }
    if (activityIdsWithSlots.isEmpty) return const [];
    return state.activityIds.entries
        .where((entry) => activityIdsWithSlots.contains(entry.value))
        .map((entry) => entry.key)
        .toList();
  }

  bool _matchesDuration(Map<String, dynamic> slot) {
    final starts = DateTime.tryParse('${slot['startsAt']}');
    final ends = DateTime.tryParse('${slot['endsAt']}');
    if (starts == null || ends == null) return true;
    return ends.difference(starts).inMinutes == state.selectedDurationMinutes;
  }

  bool _isBookable(Map<String, dynamic> slot) {
    return _isFutureAvailableSlot(slot);
  }

  bool _matchesPrice(Map<String, dynamic> slot, int? requiredPricePaise) {
    if (requiredPricePaise == null) return true;
    return _toInt(slot['pricePaise']) == requiredPricePaise;
  }

  CourtModel _toCourtModel(Map<String, dynamic> slot) {
    final slotId = slot['slotId']?.toString() ?? '';
    final facilityId = slot['facilityId']?.toString() ?? '';
    final starts =
        DateTime.tryParse('${slot['startsAt']}')?.toLocal() ?? DateTime.now();
    final ends = DateTime.tryParse('${slot['endsAt']}')?.toLocal() ?? starts;
    return CourtModel(
      id: slotId,
      name: state.facilities[facilityId] ?? 'Court',
      price: _toRupees(slot['pricePaise']),
      features: const [],
      activity: state.selectedActivity ?? '',
      venueType: '',
      turfType: '',
      slotId: slotId,
      availableQuantity: _toInt(slot['availableQuantity']),
      startsAt: starts,
      endsAt: ends,
    );
  }

  static int? _slotDurationMinutes(List<Map<String, dynamic>> slots) {
    for (final item in slots) {
      final starts = DateTime.tryParse('${item['startsAt']}');
      final ends = DateTime.tryParse('${item['endsAt']}');
      if (starts != null && ends != null) {
        return ends.difference(starts).inMinutes;
      }
    }
    return null;
  }

  static Map<String, dynamic> _normalizeSlot(Map<String, dynamic> slot) {
    return slot;
  }

  static bool _isFutureAvailableSlot(Map<String, dynamic> slot) {
    final availableQuantity = _toInt(slot['availableQuantity']);
    if (availableQuantity <= 0) return false;
    final startsAt = DateTime.tryParse('${slot['startsAt']}');
    if (startsAt == null) return true;
    return startsAt.isAfter(DateTime.now().toUtc());
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _toRupees(dynamic paise) {
    final value = paise is num ? paise : double.tryParse('$paise') ?? 0;
    return value / 100;
  }
}

final bookSlotControllerProvider =
    NotifierProvider<BookSlotController, BookSlotState>(BookSlotController.new);
