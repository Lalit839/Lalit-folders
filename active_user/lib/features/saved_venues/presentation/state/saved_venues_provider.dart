import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';

class SavedVenuesNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    final cache = SharedPrefService.savedVenuesCache;
    if (cache == null || cache.isEmpty) return [];
    try {
      final decoded = jsonDecode(cache);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(_normalizeVenue)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Map<String, dynamic> _normalizeVenue(Map<String, dynamic> venue) {
    return {
      ...venue,
      'id': venue['id']?.toString(),
      'title': venue['title']?.toString() ?? '',
      'imagePath': venue['imagePath']?.toString() ?? '',
      'distance': venue['distance']?.toString() ?? '',
      'location': venue['location']?.toString() ?? '',
      'discount': venue['discount']?.toString() ?? '',
      'rating': _number(venue['rating']).toDouble(),
      'reviews': _number(venue['reviews']).toInt(),
      'isAvailable': venue['isAvailable'] as bool? ?? true,
    };
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _persist(List<Map<String, dynamic>> venues) {
    SharedPrefService.setSavedVenuesCache(
      jsonEncode(venues),
    );
  }

  void toggleBookmark(Map<String, dynamic> venue) {
    final normalizedVenue = _normalizeVenue(venue);
    final exists = state.any((v) => v['id'] == venue['id']);

    if (exists) {
      state = state.where((v) => v['id'] != venue['id']).toList();
    } else {
      state = [...state, normalizedVenue];
    }
    _persist(state);
  }

  void setVenues(List<Map<String, dynamic>> venues) {
    state = venues.map(_normalizeVenue).toList();
    _persist(state);
  }

  void clear() {
    state = [];
    SharedPrefService.setSavedVenuesCache(null);
  }

  bool isBookmarked(String id) {
    return state.any((v) => v['id'] == id);
  }
}

final savedVenuesProvider = NotifierProvider<SavedVenuesNotifier, List<Map<String, dynamic>>>(() {
  return SavedVenuesNotifier();
});
