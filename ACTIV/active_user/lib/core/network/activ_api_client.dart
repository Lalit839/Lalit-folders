import 'dart:async';
import 'dart:convert';

import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/config/env_config.dart';
import 'package:activ_user_app/core/network/api_url_builder.dart';
import 'package:activ_user_app/core/network/mock_activ_data.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ActivApiException implements Exception {
  final String message;
  final int statusCode;

  const ActivApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ActivApiClient {
  ActivApiClient._();

  static final instance = ActivApiClient._();

  /// Set this to the app's navigator key so the client can force-redirect to
  /// login when the session expires.
  static GlobalKey<NavigatorState>? navigatorKey;

  static const _accessTokenKey = 'activ_access_token';
  static const _refreshTokenKey = 'activ_refresh_token';
  static const _timeout = Duration(seconds: 20);
  static const _otpRequestTimeout = Duration(seconds: 45);

  /// Prevents a cascade of failed requests after the session is cleared.
  bool _sessionExpired = false;
  final http.Client _client = http.Client();
  final Map<String, Future<Map<String, dynamic>>> _inFlightGetRequests = {};
  final Map<String, _AvailabilityCacheEntry> _availabilityCache = {};
  Future<bool>? _refreshFuture;
  Future<Map<String, dynamic>>? _profileFuture;
  Map<String, dynamic>? _profileCache;
  DateTime? _profileFetchedAt;

  String get _baseUrl => normalizeApiBaseUrl(dotenv.env['API_BASE_URL']);
  bool get _useMockAppData => EnvConfig.useMockAppData;

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    return _data(
      await _send(
        'POST',
        '/auth/otp/request',
        body: {'phone': phone},
        timeout: _otpRequestTimeout,
      ),
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final data = _data(
      await _send(
        'POST',
        '/auth/otp/verify',
        body: {'phone': phone, 'code': code},
      ),
    );
    final preferences = await SharedPrefService.instance();
    await SharedPrefService.setCurrentUserId(null);
    await preferences.setString(_accessTokenKey, data['accessToken'] as String);
    await preferences.setString(
      _refreshTokenKey,
      data['refreshToken'] as String,
    );
    await _storeAuthenticatedUserId(data['user']);
    _profileCache = null;
    _profileFetchedAt = null;
    _sessionExpired = false;
    return data;
  }

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    await _ensureAccessTokenForAuthenticatedRequest();
    final cached = _profileCache;
    if (!forceRefresh && cached != null) {
      if (_isProfileFresh) return Map<String, dynamic>.from(cached);
      unawaited(_refreshProfileInBackground());
      return Map<String, dynamic>.from(cached);
    }

    final existing = _profileFuture;
    if (!forceRefresh && existing != null) return existing;

    final request = _fetchProfile();
    _profileFuture = request;
    request.whenComplete(() => _profileFuture = null);
    return request;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? profilePhotoBase64,
    Map<String, dynamic>? preferences,
  }) async {
    final profile = _data(
      await _send(
        'PATCH',
        '/me',
        body: {
          'name': ?name,
          'email': ?email,
          'profilePhoto': ?profilePhotoBase64,
          'preferences': ?preferences,
        },
      ),
    );
    await _storeAuthenticatedUserId(profile);
    _profileCache = Map<String, dynamic>.from(profile);
    _profileFetchedAt = DateTime.now();
    return profile;
  }

  Future<Map<String, dynamic>> logout() async {
    final result = _data(await _send('POST', '/auth/logout'));
    _profileCache = null;
    _profileFetchedAt = null;
    return result;
  }

  Future<void> clearLocalSession() async {
    await _clearSession();
    await SharedPrefService.setLoggedIn(false);
    _sessionExpired = false;
  }

  Future<Map<String, dynamic>> requestDeletion() async {
    return _data(await _send('DELETE', '/me'));
  }

  Future<Map<String, dynamic>> getActivities() async {
    if (_useMockAppData) return _mockData(MockActivData.activities);
    try {
      return _data(await _sendCachedGet('/catalog/activities'));
    } on ActivApiException {
      if (_useMockAppData) return _mockData(MockActivData.activities);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVenues({
    String? cityCode,
    String? activityId,
    String? type,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int page = 1,
    int limit = 20,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.venues(
          cityCode: cityCode,
          activityId: activityId,
          type: type,
          page: page,
          limit: limit,
        ),
      );
    }
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (cityCode != null) query['cityCode'] = cityCode;
    if (activityId != null) query['activityId'] = activityId;
    if (type != null) query['type'] = type;
    if (latitude != null) query['latitude'] = latitude.toString();
    if (longitude != null) query['longitude'] = longitude.toString();
    if (radiusKm != null) query['radiusKm'] = radiusKm.toString();
    try {
      return _data(await _sendCachedGet('/catalog/venues', query: query));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.venues(
            cityCode: cityCode,
            activityId: activityId,
            type: type,
            page: page,
            limit: limit,
          ),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNearbyActivities({
    String? cityCode,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 20,
  }) async {
    if (_useMockAppData) return _mockData(MockActivData.activities);
    final query = <String, String>{'limit': '$limit'};
    if (cityCode != null) query['cityCode'] = cityCode;
    if (latitude != null) query['latitude'] = latitude.toString();
    if (longitude != null) query['longitude'] = longitude.toString();
    if (radiusKm != null) query['radiusKm'] = radiusKm.toString();
    return _data(
      await _sendCachedGet('/catalog/nearby-activities', query: query),
    );
  }

  Future<Map<String, dynamic>> getOperatingCities() async {
    if (_useMockAppData) {
      return _mockData(MockActivData.operatingCities);
    }
    try {
      final result = _data(await _sendCachedGet('/catalog/locations/cities'));
      final cities = result['cities'];
      if (cities is List && cities.isNotEmpty) return result;
    } catch (_) {}

    final venues = await getVenues(limit: 100);
    final byCity = <String, Map<String, dynamic>>{};
    for (final venue in (venues['items'] as List? ?? const [])) {
      if (venue is! Map<String, dynamic>) continue;
      final city =
          (venue['location'] ?? venue['city'] ?? venue['cityCode'] ?? '')
              .toString()
              .trim();
      if (city.isEmpty) continue;
      final key = city.toLowerCase();
      final existing = byCity[key];
      if (existing != null) {
        existing['venueCount'] = (existing['venueCount'] as int? ?? 1) + 1;
        continue;
      }
      byCity[key] = {
        'city': city,
        'state': venue['state']?.toString() ?? '',
        'cityCode': venue['cityCode']?.toString(),
        'latitude': (venue['latitude'] as num?)?.toDouble(),
        'longitude': (venue['longitude'] as num?)?.toDouble(),
        'venueCount': 1,
      };
    }
    return {'cities': byCity.values.toList()};
  }

  Future<Map<String, dynamic>> searchLocations(String query) async {
    if (_useMockAppData) {
      return _mockData(
        () => {'items': MockActivData.operatingCities()['cities']},
      );
    }
    try {
      return _data(
        await _sendCachedGet('/catalog/locations/search', query: {'q': query}),
      );
    } catch (_) {
      final normalized = query.trim().toLowerCase();
      final cities =
          (await getOperatingCities())['cities'] as List? ?? const [];
      return {
        'items': cities
            .whereType<Map<String, dynamic>>()
            .where((city) {
              final label = [
                city['city']?.toString() ?? '',
                city['state']?.toString() ?? '',
              ].join(' ').toLowerCase();
              return label.contains(normalized);
            })
            .map((city) {
              final cityName = city['city']?.toString() ?? '';
              final state = city['state']?.toString() ?? '';
              return {
                'placeId': city['cityCode']?.toString() ?? cityName,
                'mainText': cityName,
                'secondaryText': [
                  if (state.isNotEmpty) state,
                  'India',
                ].join(', '),
                'displayName': [
                  cityName,
                  if (state.isNotEmpty) state,
                  'India',
                ].join(', '),
                'city': cityName,
                'locality': cityName,
                'state': state,
                'country': 'India',
                'countryCode': 'IN',
                'latitude': city['latitude'],
                'longitude': city['longitude'],
              };
            })
            .toList(),
      };
    }
  }

  Future<Map<String, dynamic>> reverseLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => {
          'displayName': 'Current location',
          'mainText': 'Current location',
          'secondaryText': 'India',
          'latitude': latitude,
          'longitude': longitude,
          'country': 'India',
          'countryCode': 'IN',
        },
      );
    }
    return _data(
      await _sendCachedGet(
        '/catalog/locations/reverse',
        query: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getVenue(String venueId) async {
    if (_useMockAppData) return _mockData(() => MockActivData.venue(venueId));
    try {
      return _data(await _sendCachedGet('/venues/$venueId'));
    } on ActivApiException {
      if (_useMockAppData) return _mockData(() => MockActivData.venue(venueId));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.bookings(status: status, page: page, limit: limit),
      );
    }
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null) query['status'] = status;
    try {
      return _data(await _sendCachedGet('/bookings', query: query));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () =>
              MockActivData.bookings(status: status, page: page, limit: limit),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAvailability(
    String venueId, {
    String? date,
    String? facilityId,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.availability(
          venueId,
          date: date,
          facilityId: facilityId,
        ),
      );
    }
    final query = <String, String>{};
    if (date != null) query['date'] = date;
    if (facilityId != null) query['facilityId'] = facilityId;
    final cacheKey = _availabilityCacheKey(
      venueId,
      date: date,
      facilityId: facilityId,
    );
    final cached = _availabilityCache[cacheKey];
    if (cached != null && cached.isFresh) {
      return Map<String, dynamic>.from(cached.value);
    }
    try {
      final result = _data(
        await _sendCachedGet('/venues/$venueId/availability', query: query),
      );
      _availabilityCache[cacheKey] = _AvailabilityCacheEntry(result);
      return result;
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.availability(
            venueId,
            date: date,
            facilityId: facilityId,
          ),
        );
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getCoupons({String? bookingAttemptId}) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.coupons(bookingAttemptId: bookingAttemptId),
      );
    }
    final query = <String, String>{};
    if (bookingAttemptId != null && bookingAttemptId.isNotEmpty) {
      query['bookingAttemptId'] = bookingAttemptId;
    }
    try {
      return _list(await _sendCachedGet('/coupons', query: query));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.coupons(bookingAttemptId: bookingAttemptId),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBookingAttempt(String attemptId) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.bookingAttempt(attemptId));
    }
    try {
      return _data(await _sendCachedGet('/booking-attempts/$attemptId'));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.bookingAttempt(attemptId));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyCoupon(
    String attemptId,
    String code,
  ) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.applyCoupon(attemptId, code));
    }
    try {
      return _data(
        await _send(
          'POST',
          '/booking-attempts/$attemptId/coupon',
          body: {'code': code},
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.applyCoupon(attemptId, code));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeCoupon(String attemptId) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.removeCoupon(attemptId));
    }
    try {
      return _data(
        await _send(
          'DELETE',
          '/booking-attempts/$attemptId/coupon',
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.removeCoupon(attemptId));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.booking(bookingId));
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(await _sendCachedGet('/bookings/$bookingId'));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.booking(bookingId));
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getCalendar(DateTime from, DateTime to) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.calendar(from, to));
    }
    try {
      return _list(
        await _send(
          'GET',
          '/calendar',
          query: {
            'from': from.toUtc().toIso8601String(),
            'to': to.toUtc().toIso8601String(),
          },
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.calendar(from, to));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String message,
    String? bookingId,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.supportTicket(
          subject: subject,
          message: message,
          bookingId: bookingId,
        ),
      );
    }
    return _data(
      await _send(
        'POST',
        '/support/tickets',
        body: {'subject': subject, 'message': message, 'bookingId': ?bookingId},
      ),
    );
  }

  Future<List<dynamic>> getNotifications() async {
    if (_useMockAppData) return _mockData(MockActivData.notifications);
    try {
      return _list(await _sendCachedGet('/notifications'));
    } on ActivApiException {
      if (_useMockAppData) return _mockData(MockActivData.notifications);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDevice({
    required String platform,
    required String token,
  }) async {
    return _data(
      await _send(
        'POST',
        '/devices',
        body: {'platform': platform, 'token': token},
        idempotencyKey: _key(),
      ),
    );
  }

  Future<Map<String, dynamic>> unregisterDevice(String token) async {
    return _data(await _send('DELETE', '/devices/$token'));
  }

  Future<void> markNotificationRead(String id) async {
    if (_useMockAppData) {
      await _mockData(() {
        MockActivData.markNotificationRead(id);
        return true;
      });
      return;
    }
    await _send('PATCH', '/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    if (_useMockAppData) {
      await _mockData(() {
        MockActivData.markAllNotificationsRead();
        return true;
      });
      return;
    }
    await _send('PATCH', '/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    if (_useMockAppData) {
      await _mockData(() {
        MockActivData.deleteNotification(id);
        return true;
      });
      return;
    }
    await _send('DELETE', '/notifications/$id');
  }

  Future<List<dynamic>> getSavedVenues() async {
    if (_useMockAppData) return _mockData(MockActivData.savedVenues);
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _list(await _sendCachedGet('/me/saved-venues'));
    } on ActivApiException {
      if (_useMockAppData) return _mockData(MockActivData.savedVenues);
      rethrow;
    }
  }

  Future<void> saveVenue(String venueId) async {
    if (_useMockAppData) {
      await _mockData(() {
        MockActivData.saveVenue(venueId);
        return true;
      });
      return;
    }
    await _send('PUT', '/me/saved-venues/$venueId');
  }

  Future<void> removeSavedVenue(String venueId) async {
    if (_useMockAppData) {
      await _mockData(() {
        MockActivData.removeSavedVenue(venueId);
        return true;
      });
      return;
    }
    await _send('DELETE', '/me/saved-venues/$venueId');
  }

  Future<Map<String, dynamic>> createBookingAttempt(
    String slotId,
    int quantity,
  ) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.createBookingAttempt(slotId, quantity),
      );
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(
        await _send(
          'POST',
          '/booking-attempts',
          body: {'slotId': slotId, 'quantity': quantity},
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.createBookingAttempt(slotId, quantity),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPaymentOrder(String attemptId) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.createPaymentOrder(attemptId));
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(
        await _send(
          'POST',
          '/booking-attempts/$attemptId/payment-order',
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.createPaymentOrder(attemptId));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.payment(paymentId));
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(await _sendCachedGet('/payments/$paymentId'));
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(() => MockActivData.payment(paymentId));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmRazorpayPayment({
    required String paymentId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.payment(paymentId));
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    return _data(
      await _send(
        'POST',
        '/payments/razorpay/confirm',
        body: {
          'paymentId': paymentId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpayOrderId': razorpayOrderId,
          'razorpaySignature': razorpaySignature,
        },
        idempotencyKey: _key(),
      ),
    );
  }

  Future<Map<String, dynamic>> rescheduleBooking(
    String bookingId,
    String slotId,
  ) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.rescheduleBooking(bookingId, slotId),
      );
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(
        await _send(
          'POST',
          '/bookings/$bookingId/reschedule',
          body: {'slotId': slotId},
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.rescheduleBooking(bookingId, slotId),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.cancelBooking(bookingId, reason: reason),
      );
    }
    await _ensureAccessTokenForAuthenticatedRequest();
    try {
      return _data(
        await _send(
          'POST',
          '/bookings/$bookingId/cancel',
          body: {'reason': reason},
          idempotencyKey: _key(),
        ),
      );
    } on ActivApiException {
      if (_useMockAppData) {
        return _mockData(
          () => MockActivData.cancelBooking(bookingId, reason: reason),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitReview(
    String bookingId, {
    required int rating,
    required String body,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.submitReview(bookingId, rating: rating, body: body),
      );
    }
    return _data(
      await _send(
        'POST',
        '/bookings/$bookingId/review',
        body: {'rating': rating, 'body': body},
        idempotencyKey: _key(),
      ),
    );
  }

  Future<List<dynamic>> getReviewHistory() async {
    if (_useMockAppData) {
      return _mockData(MockActivData.reviewHistory);
    }
    return _list(await _sendCachedGet('/me/reviews'));
  }

  Future<Map<String, dynamic>> editReview(
    String reviewId, {
    required int rating,
    required String body,
  }) async {
    if (_useMockAppData) {
      return _mockData(
        () => MockActivData.editReview(reviewId, rating: rating, body: body),
      );
    }
    return _data(
      await _send(
        'PATCH',
        '/reviews/$reviewId',
        body: {'rating': rating, 'body': body},
        idempotencyKey: _key(),
      ),
    );
  }

  Future<Map<String, dynamic>> generateShareCard(
    DateTime from,
    DateTime to,
  ) async {
    if (_useMockAppData) {
      return _mockData(() => MockActivData.shareCard(from, to));
    }
    return _data(
      await _send(
        'POST',
        '/share-cards',
        body: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
        idempotencyKey: _key(),
      ),
    );
  }

  Future<List<dynamic>> getFaqs() async {
    if (_useMockAppData) return MockActivData.faqs();
    try {
      return _list(await _sendCachedGet('/content/faqs'));
    } on ActivApiException {
      if (_useMockAppData) return MockActivData.faqs();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPolicy(String type) async {
    if (_useMockAppData) return MockActivData.policy(type);
    try {
      return _data(await _sendCachedGet('/content/policies/$type'));
    } on ActivApiException {
      if (_useMockAppData) return MockActivData.policy(type);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? idempotencyKey,
    Duration? timeout,
  }) async {
    final stopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    if (_sessionExpired && _isAuthPath(path)) {
      _sessionExpired = false;
    }
    if (_sessionExpired) {
      throw const ActivApiException(
        'Session expired. Please log in again.',
        401,
      );
    }

    var response = await _execute(
      method,
      path,
      body: body,
      query: query,
      idempotencyKey: idempotencyKey,
      timeout: timeout,
    );
    if (response.statusCode == 401 && !_isAuthPath(path)) {
      if (await _refreshTokens()) {
        response = await _execute(
          method,
          path,
          body: body,
          query: query,
          idempotencyKey: idempotencyKey,
          timeout: timeout,
        );
      } else {
        _sessionExpired = true;
        _forceNavigateToLogin();
        throw const ActivApiException(
          'Session expired. Please log in again.',
          401,
        );
      }
    }
    try {
      return _decode(response);
    } finally {
      _logRequestTiming(method, path, response.statusCode, stopwatch);
    }
  }

  Future<Map<String, dynamic>> _sendCachedGet(
    String path, {
    Map<String, String>? query,
  }) {
    final uri = buildApiUri(_baseUrl, path, query: query);
    final key = uri.toString();
    final inFlight = _inFlightGetRequests[key];
    if (inFlight != null) return inFlight;

    final request = _send('GET', path, query: query);
    _inFlightGetRequests[key] = request;
    request.whenComplete(() => _inFlightGetRequests.remove(key));
    return request;
  }

  Future<http.Response> _execute(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? idempotencyKey,
    Duration? timeout,
  }) async {
    final uri = buildApiUri(_baseUrl, path, query: query);
    final preferences = await SharedPrefService.instance();
    final token = preferences.getString(_accessTokenKey);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
    final encodedBody = body == null ? null : jsonEncode(body);
    final requestTimeout = timeout ?? _timeout;
    try {
      return switch (method) {
        'GET' =>
          await _client.get(uri, headers: headers).timeout(requestTimeout),
        'POST' =>
          await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(requestTimeout),
        'PATCH' =>
          await _client
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(requestTimeout),
        'PUT' =>
          await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(requestTimeout),
        'DELETE' =>
          await _client.delete(uri, headers: headers).timeout(requestTimeout),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      };
    } on TimeoutException {
      throw const ActivApiException(
        'Connection timed out. Please check your network and try again.',
        0,
      );
    } on http.ClientException {
      throw const ActivApiException(
        'Cannot reach server. Please try again.',
        0,
      );
    }
  }

  Future<bool> _refreshTokens() async {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final refresh = _refreshTokensUnshared();
    _refreshFuture = refresh;
    refresh.whenComplete(() => _refreshFuture = null);
    return refresh;
  }

  Future<bool> _refreshTokensUnshared() async {
    final preferences = await SharedPrefService.instance();
    final refreshToken = preferences.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearSession();
      _sessionExpired = true;
      _forceNavigateToLogin();
      return false;
    }
    try {
      final uri = buildApiUri(_baseUrl, '/auth/token/refresh');
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final accessToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;
          if (accessToken != null) {
            await preferences.setString(_accessTokenKey, accessToken);
          }
          if (newRefreshToken != null) {
            await preferences.setString(_refreshTokenKey, newRefreshToken);
          }
          _sessionExpired = false;
          return accessToken != null;
        }
      }
    } catch (_) {}
    await _clearSession();
    _sessionExpired = true;
    _forceNavigateToLogin();
    return false;
  }

  Future<void> _ensureAccessTokenForAuthenticatedRequest() async {
    final preferences = await SharedPrefService.instance();
    final accessToken = preferences.getString(_accessTokenKey);
    if (_isAccessTokenUsable(accessToken)) return;
    await _refreshTokens();
  }

  bool _isAccessTokenUsable(String? token) {
    if (token == null || token.isEmpty) return false;
    final parts = token.split('.');
    if (parts.length != 3) return true;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return true;
      final exp = payload['exp'];
      if (exp is! num) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
      return expiresAt.isAfter(
        DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );
    } catch (_) {
      return true;
    }
  }

  void _forceNavigateToLogin() {
    final key = navigatorKey;
    final navigator = key?.currentState;
    if (navigator == null) return;
    scheduleMicrotask(() {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => route.isFirst,
      );
    });
  }

  Future<void> _clearSession() async {
    final preferences = await SharedPrefService.instance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await SharedPrefService.clearActiveAccountCache();
    await SharedPrefService.setCurrentUserId(null);
    _profileCache = null;
    _profileFetchedAt = null;
    _availabilityCache.clear();
    MockActivData.endSession();
  }

  Future<T> _mockData<T>(T Function() create) async {
    await _scopeMockDataToAuthenticatedUser();
    final scenario = EnvConfig.mockAppDataScenario;
    if (scenario == 'delay') {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    if (scenario == 'error' || scenario == 'failure') {
      throw const ActivApiException('Mock app data failure.', 503);
    }
    final result = create();
    if (scenario == 'empty') {
      final empty = _emptyMockResult(result);
      if (empty is T) return empty;
    }
    return result;
  }

  Object? _emptyMockResult(Object? result) {
    if (result is List) return <dynamic>[];
    if (result is Map<String, dynamic> && result['items'] is List) {
      return {...result, 'items': <dynamic>[], 'total': 0};
    }
    return null;
  }

  Future<void> _scopeMockDataToAuthenticatedUser() async {
    final userId = SharedPrefService.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      MockActivData.startSession(userId);
    }
  }

  Future<void> _storeAuthenticatedUserId(dynamic user) async {
    if (user is! Map<String, dynamic>) return;
    final userId =
        user['id']?.toString() ??
        user['userId']?.toString() ??
        user['sub']?.toString();
    if (userId == null || userId.isEmpty) return;
    await SharedPrefService.setCurrentUserId(userId);
    MockActivData.startSession(userId);
  }

  bool get _isProfileFresh {
    final fetchedAt = _profileFetchedAt;
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < const Duration(minutes: 2);
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final profile = _data(await _send('GET', '/me'));
    await _storeAuthenticatedUserId(profile);
    _profileCache = Map<String, dynamic>.from(profile);
    _profileFetchedAt = DateTime.now();
    return Map<String, dynamic>.from(profile);
  }

  Future<void> _refreshProfileInBackground() async {
    if (_profileFuture != null) return;
    try {
      await getProfile(forceRefresh: true);
    } catch (_) {
      // Keep the last known profile; foreground calls still surface failures.
    }
  }

  String _availabilityCacheKey(
    String venueId, {
    String? date,
    String? facilityId,
  }) => '$venueId|${date ?? ''}|${facilityId ?? ''}';

  bool _isAuthPath(String path) => path.startsWith('/auth/');

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message']?.toString()
          : null;
      throw ActivApiException(message ?? 'Request failed', response.statusCode);
    }
    return decoded;
  }

  String _key() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}';

  void _logRequestTiming(
    String method,
    String path,
    int statusCode,
    Stopwatch? stopwatch,
  ) {
    if (stopwatch == null) return;
    stopwatch.stop();
    debugPrint(
      '[ACTIV perf] $method $path -> $statusCode in '
      '${stopwatch.elapsedMilliseconds}ms',
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  List<dynamic> _list(Map<String, dynamic> response) {
    final data = response['data'];
    return data is List ? data : const [];
  }
}

class _AvailabilityCacheEntry {
  _AvailabilityCacheEntry(this.value) : createdAt = DateTime.now();

  static const ttl = Duration(seconds: 3);

  final Map<String, dynamic> value;
  final DateTime createdAt;

  bool get isFresh => DateTime.now().difference(createdAt) < ttl;
}
