class BookSlotState {
  final String? venueId;
  final String? venueName;
  final String? venueCity;
  final DateTime? selectedDate;
  final String? selectedActivity;
  final int selectedDurationMinutes;
  final DateTime? selectedStartTime;
  final List<String> selectedCourtIds;
  final int playerCount;
  final bool isLoading;
  final List<Map<String, dynamic>> availability;
  final Map<String, String> facilities;
  final Map<String, String> activityIds;
  final Map<String, String> facilityActivityIds;
  final List<String> activityNames;
  final String? errorMessage;

  BookSlotState({
    this.venueId,
    this.venueName,
    this.venueCity,
    this.selectedDate,
    this.selectedActivity,
    this.selectedDurationMinutes = 60,
    this.selectedStartTime,
    this.selectedCourtIds = const [],
    this.playerCount = 1,
    this.isLoading = false,
    this.availability = const [],
    this.facilities = const {},
    this.activityIds = const {},
    this.facilityActivityIds = const {},
    this.activityNames = const [],
    this.errorMessage,
  });

  BookSlotState copyWith({
    String? venueId,
    String? venueName,
    String? venueCity,
    DateTime? selectedDate,
    String? selectedActivity,
    int? selectedDurationMinutes,
    DateTime? selectedStartTime,
    List<String>? selectedCourtIds,
    int? playerCount,
    bool? isLoading,
    List<Map<String, dynamic>>? availability,
    Map<String, String>? facilities,
    Map<String, String>? activityIds,
    Map<String, String>? facilityActivityIds,
    List<String>? activityNames,
    String? errorMessage,
    bool clearVenueId = false,
    bool clearVenueName = false,
    bool clearVenueCity = false,
    bool clearSelectedActivity = false,
    bool clearStartTime = false,
    bool clearCourtIds = false,
    bool clearError = false,
  }) {
    return BookSlotState(
      venueId: clearVenueId ? null : (venueId ?? this.venueId),
      venueName: clearVenueName ? null : (venueName ?? this.venueName),
      venueCity: clearVenueCity ? null : (venueCity ?? this.venueCity),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedActivity: clearSelectedActivity
          ? null
          : (selectedActivity ?? this.selectedActivity),
      selectedDurationMinutes:
          selectedDurationMinutes ?? this.selectedDurationMinutes,
      selectedStartTime: clearStartTime ? null : (selectedStartTime ?? this.selectedStartTime),
      selectedCourtIds: clearCourtIds ? const [] : (selectedCourtIds ?? this.selectedCourtIds),
      playerCount: playerCount ?? this.playerCount,
      isLoading: isLoading ?? this.isLoading,
      availability: availability ?? this.availability,
      facilities: facilities ?? this.facilities,
      activityIds: activityIds ?? this.activityIds,
      facilityActivityIds: facilityActivityIds ?? this.facilityActivityIds,
      activityNames: activityNames ?? this.activityNames,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage));
  }
}
