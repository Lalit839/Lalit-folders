import 'dart:convert';

import 'package:activ_user_app/core/models/selected_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> instance() async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  static const String _keyOnboardingCompleted = 'isOnboardingCompleted';
  static const String _keyUserName = 'userName';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyProfilePhoto = 'profilePhotoBase64';
  static const String _keyCurrentUserId = 'currentUserId';
  static const String _keyOutOfBoundsNotify = 'outOfBoundsNotifyMe';
  static const String _keyHasUnreadNotifications = 'hasUnreadNotifications';
  static const String _keySelectedLocation = 'selectedLocation';

  static String? get currentUserId {
    return _prefs?.getString(_keyCurrentUserId);
  }

  static Future<bool> setCurrentUserId(String? userId) async {
    if (_prefs == null) await init();
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return await _prefs!.remove(_keyCurrentUserId);
    }
    return await _prefs!.setString(_keyCurrentUserId, normalized);
  }

  static String _scopedKey(String key) {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return key;
    return '$key:$userId';
  }

  // Get onboarding completed status
  static bool get isOnboardingCompleted {
    return _prefs?.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Set onboarding completed status
  static Future<bool> setOnboardingCompleted(bool completed) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_keyOnboardingCompleted, completed);
  }

  static String? get userName {
    return _prefs?.getString(_scopedKey(_keyUserName));
  }

  static Future<bool> setUserName(String name) async {
    if (_prefs == null) await init();
    final key = _scopedKey(_keyUserName);
    if (name.isEmpty) return await _prefs!.remove(key);
    return await _prefs!.setString(key, name);
  }

  static bool get isLoggedIn {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<bool> setLoggedIn(bool loggedIn) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_keyIsLoggedIn, loggedIn);
  }

  static String? get userEmail {
    return _prefs?.getString(_scopedKey(_keyUserEmail));
  }

  static Future<bool> setUserEmail(String email) async {
    if (_prefs == null) await init();
    final key = _scopedKey(_keyUserEmail);
    if (email.isEmpty) return await _prefs!.remove(key);
    return await _prefs!.setString(key, email);
  }

  static String? get profilePhotoBase64 {
    return _prefs?.getString(_scopedKey(_keyProfilePhoto));
  }

  static Future<bool> setProfilePhotoBase64(String? base64) async {
    if (_prefs == null) await init();
    final key = _scopedKey(_keyProfilePhoto);
    if (base64 == null || base64.isEmpty) {
      return await _prefs!.remove(key);
    }
    return await _prefs!.setString(key, base64);
  }

  static bool get outOfBoundsNotifyMe {
    return _prefs?.getBool(_keyOutOfBoundsNotify) ?? false;
  }

  static Future<bool> setOutOfBoundsNotifyMe(bool value) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_keyOutOfBoundsNotify, value);
  }

  // Unread notifications indicator (defaults to true so the bell dot
  // shows until the user opens the notifications screen for the first time)
  static bool get hasUnreadNotifications {
    return _prefs?.getBool(_keyHasUnreadNotifications) ?? true;
  }

  static Future<bool> setHasUnreadNotifications(bool value) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_keyHasUnreadNotifications, value);
  }

  static SelectedLocation? get selectedLocation {
    final raw = _prefs?.getString(_scopedKey(_keySelectedLocation));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SelectedLocation.fromJson(decoded);
      }
      if (decoded is Map) {
        return SelectedLocation.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> setSelectedLocation(SelectedLocation? location) async {
    if (_prefs == null) await init();
    final key = _scopedKey(_keySelectedLocation);
    if (location == null) return await _prefs!.remove(key);
    return await _prefs!.setString(key, jsonEncode(location.toJson()));
  }

  static String? get savedVenuesCache {
    return _prefs?.getString(_scopedKey('savedVenuesCache'));
  }

  static Future<bool> setSavedVenuesCache(String? json) async {
    if (_prefs == null) await init();
    final key = _scopedKey('savedVenuesCache');
    if (json == null || json.isEmpty) {
      return await _prefs!.remove(key);
    }
    return await _prefs!.setString(key, json);
  }

  static String? get homeActivitiesCache {
    return _prefs?.getString(_scopedKey('homeActivitiesCache'));
  }

  static Future<bool> setHomeActivitiesCache(String? json) async {
    if (_prefs == null) await init();
    final key = _scopedKey('homeActivitiesCache');
    if (json == null || json.isEmpty) {
      return await _prefs!.remove(key);
    }
    return await _prefs!.setString(key, json);
  }

  static String? get homeVenuesCache {
    return _prefs?.getString(_scopedKey('homeVenuesCache'));
  }

  static Future<bool> setHomeVenuesCache(String? json) async {
    if (_prefs == null) await init();
    final key = _scopedKey('homeVenuesCache');
    if (json == null || json.isEmpty) {
      return await _prefs!.remove(key);
    }
    return await _prefs!.setString(key, json);
  }

  static Future<void> clearActiveAccountCache() async {
    if (_prefs == null) await init();
    await setUserName('');
    await setUserEmail('');
    await setProfilePhotoBase64(null);
    await setSavedVenuesCache(null);
    await setHomeActivitiesCache(null);
    await setHomeVenuesCache(null);
    await setSelectedLocation(null);
  }

  // Clear preferences (for testing/debugging purposes)
  static Future<bool> clear() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }

  static void resetForTesting() {
    _prefs = null;
  }
}
