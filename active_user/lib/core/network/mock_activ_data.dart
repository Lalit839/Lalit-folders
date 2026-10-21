import 'package:activ_user_app/core/constants/app_assets.dart';

class MockActivData {
  MockActivData._();

  static const _fallbackUserId = 'anonymous';

  static String _currentUserId = _fallbackUserId;
  static final Map<String, _MockUserState> _userStates = {};

  static const _image = 'assets/images/turf.jpg';

  static _MockUserState get _state => _userStates.putIfAbsent(
    _currentUserId,
    () => _MockUserState(_currentUserId),
  );

  static String get currentUserId => _currentUserId;

  static Map<String, dynamic> startSession(String userId) {
    _currentUserId = userId.trim().isEmpty ? _fallbackUserId : userId.trim();
    return profile();
  }

  static void endSession() {
    _currentUserId = _fallbackUserId;
  }

  static void resetForCurrentUser() {
    _userStates.remove(_currentUserId);
  }

  static void resetAll() {
    _userStates.clear();
    endSession();
  }

  static List<Map<String, dynamic>> get _activities => [
    _activity(
      'act_adventure',
      'Adventure Sports',
      'adventure_sports',
      AppAssets.adventureSports,
    ),
    _activity('act_archery', 'Archery', 'archery', AppAssets.archery),
    _activity('act_badminton', 'Badminton', 'badminton', AppAssets.badminton),
    _activity(
      'act_basketball',
      'Basketball',
      'basketball',
      AppAssets.basketball,
    ),
    _activity(
      'act_bouldering',
      'Bouldering',
      'bouldering',
      AppAssets.bouldering,
    ),
    _activity('act_bowling', 'Bowling', 'bowling', AppAssets.bowling),
    _activity('act_boxing', 'Boxing', 'boxing', AppAssets.boxing),
    _activity(
      'act_cricket_nets',
      'Cricket Nets',
      'cricket_nets',
      AppAssets.cricketNets,
    ),
    _activity('act_crossfit', 'Crossfit', 'crossfit', AppAssets.crossfit),
    _activity('act_dance', 'Dance', 'dance', AppAssets.dance),
    _activity(
      'act_equestrian',
      'Equestrian',
      'equestrian',
      AppAssets.equestrian,
    ),
    _activity(
      'act_football',
      'Football Turf',
      'football',
      AppAssets.footballTurf,
    ),
    _activity('act_gym', 'Gym', 'gym', AppAssets.gym),
    _activity('act_mma', 'MMA', 'mma', AppAssets.mma),
    _activity('act_padel', 'Padel', 'padel', AppAssets.padel),
    _activity(
      'act_pickleball',
      'Pickleball',
      'pickleball',
      AppAssets.pickleball,
    ),
    _activity('act_pool', 'Pool', 'pool', AppAssets.pool),
    _activity('act_swimming', 'Swimming', 'swimming', AppAssets.swimming),
    _activity('act_tennis', 'Tennis', 'tennis', AppAssets.tennis),
    _activity('act_yoga', 'Yoga', 'yoga', AppAssets.yoga),
  ];

  static List<Map<String, dynamic>> get _venues => [
    _venue(
      id: 'venue_box_01',
      name: 'ACTIV Box Arena',
      city: 'Indore',
      address: 'Vijay Nagar, Indore',
      rating: 4.8,
      reviews: 324,
      activityIds: ['act_boxing', 'act_mma', 'act_crossfit'],
    ),
    _venue(
      id: 'venue_turf_02',
      name: 'Greenline Turf Club',
      city: 'Indore',
      address: 'Scheme 140, Indore',
      rating: 4.6,
      reviews: 218,
      activityIds: ['act_football', 'act_cricket_nets'],
    ),
    _venue(
      id: 'venue_fit_03',
      name: 'Urban Fit Studio',
      city: 'Indore',
      address: 'New Palasia, Indore',
      rating: 4.7,
      reviews: 189,
      activityIds: ['act_gym', 'act_yoga', 'act_dance'],
    ),
    _venue(
      id: 'venue_racket_04',
      name: 'Smash Racket Hub',
      city: 'Indore',
      address: 'Rau, Indore',
      rating: 4.5,
      reviews: 156,
      activityIds: ['act_badminton', 'act_tennis', 'act_pickleball'],
    ),
    _venue(
      id: 'venue_bowl_05',
      name: 'Pin & Pocket Social',
      city: 'Indore',
      address: 'C21 Mall, Indore',
      rating: 4.4,
      reviews: 141,
      activityIds: ['act_bowling', 'act_pool'],
    ),
    _venue(
      id: 'venue_climb_06',
      name: 'Summit Adventure Park',
      city: 'Indore',
      address: 'Bypass Road, Indore',
      rating: 4.9,
      reviews: 92,
      activityIds: ['act_adventure', 'act_bouldering', 'act_archery'],
    ),
    _venue(
      id: 'venue_court_07',
      name: 'Hoop House',
      city: 'Indore',
      address: 'AB Road, Indore',
      rating: 4.3,
      reviews: 77,
      activityIds: ['act_basketball'],
    ),
    _venue(
      id: 'venue_aqua_08',
      name: 'Blue Lane Aquatics',
      city: 'Indore',
      address: 'Bicholi Mardana, Indore',
      rating: 4.6,
      reviews: 126,
      activityIds: ['act_swimming'],
    ),
  ];

  static Map<String, dynamic> activities() => {'items': _activities};

  static Map<String, dynamic> operatingCities() {
    final byCity = <String, int>{};
    for (final venue in _venues) {
      final city = venue['cityCode']?.toString() ?? '';
      if (city.isEmpty) continue;
      byCity[city] = (byCity[city] ?? 0) + 1;
    }
    return {
      'cities': byCity.entries
          .map(
            (entry) => {
              'city': entry.key,
              'state': '',
              'cityCode': entry.key,
              'latitude': 22.7196,
              'longitude': 75.8577,
              'venueCount': entry.value,
            },
          )
          .toList(),
    };
  }

  static Map<String, dynamic> venues({
    String? cityCode,
    String? activityId,
    String? type,
    int page = 1,
    int limit = 20,
  }) {
    final filtered = _venues.where((venue) {
      if (cityCode != null && cityCode.isNotEmpty) {
        final city = (venue['cityCode'] ?? '').toString().toLowerCase();
        if (city != cityCode.toLowerCase()) return false;
      }
      if (activityId != null && activityId.isNotEmpty) {
        final hasActivity = (venue['activities'] as List).any((item) {
          final activity = item['activity'] as Map<String, dynamic>;
          return activity['id'] == activityId;
        });
        if (!hasActivity) return false;
      }
      if (type != null && type.isNotEmpty) {
        final venueType = (venue['type'] ?? '').toString().toUpperCase();
        if (venueType != type.toUpperCase()) return false;
      }
      return true;
    }).toList();
    final start = (page - 1).clamp(0, filtered.length).toInt();
    final end = (start + limit).clamp(0, filtered.length).toInt();
    return {
      'items': filtered.sublist(start, end),
      'page': page,
      'limit': limit,
      'total': filtered.length,
    };
  }

  static Map<String, dynamic> venue(String venueId) {
    return _venues.firstWhere(
      (venue) => venue['id'] == venueId,
      orElse: () => _venues.first,
    );
  }

  static Map<String, dynamic> availability(
    String venueId, {
    String? date,
    String? facilityId,
  }) {
    final venueData = venue(venueId);
    final facilities = (venueData['facilities'] as List)
        .cast<Map<String, dynamic>>();
    final day = DateTime.tryParse(date ?? '') ?? DateTime.now();
    final localDay = DateTime(day.year, day.month, day.day);
    final slots = <Map<String, dynamic>>[];

    for (final facility in facilities) {
      if (facilityId != null && facility['id'] != facilityId) continue;
      for (final hour in const [6, 7, 8, 10, 12, 16, 18, 20, 21]) {
        final startsLocal = localDay.add(Duration(hours: hour));
        final endsLocal = startsLocal.add(const Duration(hours: 1));
        final price = _priceForHour(hour);
        slots.add({
          'slotId': '${facility['id']}_${_dateKey(localDay)}_$hour',
          'id': '${facility['id']}_${_dateKey(localDay)}_$hour',
          'facilityId': facility['id'],
          'startsAt': startsLocal.toUtc().toIso8601String(),
          'endsAt': endsLocal.toUtc().toIso8601String(),
          'pricePaise': price,
          'currency': 'INR',
          'capacity': 8,
          'availableQuantity': hour == 18 ? 1 : (hour == 20 ? 2 : 6),
          'status': 'AVAILABLE',
        });
      }
    }

    return {'items': slots};
  }

  static Map<String, dynamic> bookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    _seedBookings();
    final wanted = status?.toUpperCase();
    final filtered =
        _state.bookings.values.where((booking) {
            if (wanted == null) return true;
            final current = booking['status']?.toString().toUpperCase();
            return current == wanted ||
                (wanted == 'CONFIRMED' && current == 'RESCHEDULED');
          }).toList()
          ..sort((a, b) => '${a['startsAt']}'.compareTo('${b['startsAt']}'));
    return {
      'items': filtered.take(limit).toList(),
      'page': page,
      'limit': limit,
      'total': filtered.length,
    };
  }

  static Map<String, dynamic> booking(String bookingId) {
    _seedBookings();
    return _state.bookings[bookingId] ?? _state.bookings.values.first;
  }

  static Map<String, dynamic> createBookingAttempt(
    String slotId,
    int quantity,
  ) {
    final slot = _slotById(slotId);
    final attemptId = 'attempt_${_state.attemptCounter++}';
    final quote = _quote(slot, quantity);
    final attempt = {
      'id': attemptId,
      'attemptId': attemptId,
      'slotId': slotId,
      'quantity': quantity,
      'quote': quote,
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
    };
    _state.attempts[attemptId] = attempt;
    return attempt;
  }

  static Map<String, dynamic> bookingAttempt(String attemptId) {
    return _state.attempts[attemptId] ??
        createBookingAttempt(_firstFutureSlot()['slotId'], 2);
  }

  static Map<String, dynamic> applyCoupon(String attemptId, String code) {
    final attempt = bookingAttempt(attemptId);
    final slot = _slotById(attempt['slotId'].toString());
    final quantity = int.tryParse('${attempt['quantity']}') ?? 1;
    final quote = _quote(slot, quantity, couponCode: code);
    attempt['couponCode'] = code;
    attempt['quote'] = quote;
    _state.attempts[attemptId] = attempt;
    return attempt;
  }

  static Map<String, dynamic> removeCoupon(String attemptId) {
    final attempt = bookingAttempt(attemptId);
    final slot = _slotById(attempt['slotId'].toString());
    final quantity = int.tryParse('${attempt['quantity']}') ?? 1;
    attempt.remove('couponCode');
    attempt['quote'] = _quote(slot, quantity);
    _state.attempts[attemptId] = attempt;
    return attempt;
  }

  static List<Map<String, dynamic>> coupons({String? bookingAttemptId}) => [
    {
      'code': 'NEWUSER20',
      'percentOff': 20,
      'endsAt': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
    },
    {
      'code': 'FLAT100',
      'amountOff': 10000,
      'endsAt': DateTime.now().add(const Duration(days: 8)).toIso8601String(),
    },
    {
      'code': 'PLAY15',
      'percentOff': 15,
      'endsAt': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
    },
  ];

  static Map<String, dynamic> createPaymentOrder(String attemptId) {
    final attempt = bookingAttempt(attemptId);
    final paymentId = 'pay_mock_${_state.paymentCounter++}';
    final bookingId = 'booking_mock_${_state.bookingCounter++}';
    final bookingData = _bookingFromAttempt(bookingId, attempt);
    _state.bookings[bookingId] = bookingData;
    final payment = {
      'paymentId': paymentId,
      'id': paymentId,
      'bookingId': bookingId,
      'orderId': 'order_mock_$paymentId',
      'amount': (attempt['quote'] as Map<String, dynamic>)['total'],
      'amountPaise': (attempt['quote'] as Map<String, dynamic>)['total'],
      'currency': 'INR',
      'status': 'CAPTURED',
      'demo': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _state.payments[paymentId] = payment;
    bookingData['payments'] = [payment];
    return payment;
  }

  static Map<String, dynamic> payment(String paymentId) {
    return _state.payments[paymentId] ??
        {
          'id': paymentId,
          'paymentId': paymentId,
          'status': 'CAPTURED',
          'amount': 0,
          'currency': 'INR',
          'demo': true,
        };
  }

  static Map<String, dynamic> rescheduleBooking(
    String bookingId,
    String slotId,
  ) {
    final bookingData = booking(bookingId);
    final slot = _slotById(slotId);
    bookingData
      ..['slot'] = slot['slot']
      ..['startsAt'] = slot['startsAt']
      ..['status'] = 'RESCHEDULED'
      ..['rescheduleCount'] =
          (int.tryParse('${bookingData['rescheduleCount']}') ?? 0) + 1;
    _state.bookings[bookingId] = bookingData;
    return bookingData;
  }

  static Map<String, dynamic> cancelBooking(
    String bookingId, {
    String? reason,
  }) {
    final bookingData = booking(bookingId);
    final paid = int.tryParse('${bookingData['totalPaise']}') ?? 0;
    bookingData
      ..['status'] = 'CANCELLED'
      ..['cancelReason'] = reason
      ..['refunds'] = [
        {
          'id': 'refund_$bookingId',
          'amountPaise': (paid * 0.9).round(),
          'status': 'PROCESSING',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      ];
    _state.bookings[bookingId] = bookingData;
    return bookingData;
  }

  static List<Map<String, dynamic>> calendar(DateTime from, DateTime to) {
    _seedBookings();
    return _state.bookings.values
        .where((booking) {
          final starts = DateTime.tryParse('${booking['startsAt']}');
          return starts != null && starts.isAfter(from) && starts.isBefore(to);
        })
        .map((booking) {
          final slot = booking['slot'] as Map<String, dynamic>;
          final facility = slot['facility'] as Map<String, dynamic>;
          return {
            'id': booking['id'],
            'title': facility['name'],
            'sport': facility['name'],
            'startsAt': booking['startsAt'],
            'endsAt': slot['endsAt'],
            'status': booking['status'],
          };
        })
        .toList();
  }

  static List<Map<String, dynamic>> savedVenues() =>
      _state.savedVenueIds.map((id) => {'venue': venue(id)}).toList();

  static void saveVenue(String venueId) => _state.savedVenueIds.add(venueId);

  static void removeSavedVenue(String venueId) =>
      _state.savedVenueIds.remove(venueId);

  static List<Map<String, dynamic>> notifications() {
    _seedBookings();
    final bookingId = _state.bookings.keys.first;
    final items = [
      {
        'id': 'notif_booking',
        'title': 'Booking confirmed',
        'body': 'Your ACTIV slot is ready. Tap to view details.',
        'type': 'booking',
        'targetType': 'booking',
        'targetId': bookingId,
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
      },
      {
        'id': 'notif_offer',
        'title': 'New offer unlocked',
        'body': 'Use NEWUSER20 on your next booking.',
        'type': 'offer',
        'createdAt': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
    ];
    return items
        .where((item) => !_state.deletedNotificationIds.contains(item['id']))
        .map(
          (item) => {
            ...item,
            'isRead': _state.readNotificationIds.contains(item['id']),
          },
        )
        .toList();
  }

  static void markNotificationRead(String id) =>
      _state.readNotificationIds.add(id);

  static void markAllNotificationsRead() {
    for (final item in notifications()) {
      _state.readNotificationIds.add(item['id'].toString());
    }
  }

  static void deleteNotification(String id) =>
      _state.deletedNotificationIds.add(id);

  static Map<String, dynamic> submitReview(
    String bookingId, {
    required int rating,
    required String body,
  }) {
    final review = {
      'id': 'review_${_state.reviewCounter++}',
      'bookingId': bookingId,
      'rating': rating,
      'body': body,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _state.reviews[review['id'].toString()] = review;
    return review;
  }

  static List<Map<String, dynamic>> reviewHistory() {
    return _state.reviews.values.toList()
      ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
  }

  static Map<String, dynamic> editReview(
    String reviewId, {
    required int rating,
    required String body,
  }) {
    final existing = _state.reviews[reviewId] ??
        {
          'id': reviewId,
          'bookingId': '',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        };
    existing
      ..['rating'] = rating
      ..['body'] = body;
    _state.reviews[reviewId] = existing;
    return existing;
  }

  static Map<String, dynamic> policy(String type) {
    final title = switch (type) {
      'cancellation-policy' => 'Cancellation Policy',
      'refund-policy' => 'Refund Policy',
      _ => 'Reschedule Policy',
    };
    final body = switch (type) {
      'cancellation-policy' =>
        'Cancel up to 2 hours before the slot for a 90% refund. Cancellations inside 2 hours are reviewed by the venue. Refunds are processed to the original payment method.',
      'refund-policy' =>
        'Approved refunds are initiated immediately. Bank processing may take 3 to 5 working days. Failed payments are automatically reversed after confirmation.',
      _ =>
        'Bookings can be rescheduled once before the slot starts. Select a future available slot at the same venue. Any price difference is recalculated before confirmation.',
    };
    return {'type': type, 'title': title, 'body': body};
  }

  static List<Map<String, dynamic>> faqs() => [
    {
      'id': 'faq_1',
      'question': 'How do I book a slot?',
      'answer':
          'Open a venue, choose an activity, pick a time, and complete payment.',
    },
    {
      'id': 'faq_2',
      'question': 'Can I reschedule?',
      'answer':
          'Yes, confirmed bookings can be rescheduled once when future slots are available.',
    },
  ];

  static Map<String, dynamic> supportTicket({
    required String subject,
    required String message,
    String? bookingId,
  }) => {
    'id': 'ticket_${DateTime.now().millisecondsSinceEpoch}',
    'subject': subject,
    'message': message,
    'bookingId': bookingId,
    'status': 'OPEN',
  };

  static Map<String, dynamic> shareCard(DateTime from, DateTime to) => {
    'imageUrl': '',
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
  };

  static Map<String, dynamic> profile() => Map<String, dynamic>.from(
    _state.profile,
  );

  static Map<String, dynamic> updateProfile(Map<String, dynamic> values) {
    _state.profile.addAll(values);
    return profile();
  }

  static Map<String, dynamic> _activity(
    String id,
    String name,
    String sportCode,
    String iconAsset,
  ) => {
    'id': id,
    'name': name,
    'sportCode': sportCode,
    'iconAsset': iconAsset,
    'iconUrl': '',
    'variations': ['Indoor', 'Coaching', 'Pay per session'],
  };

  static Map<String, dynamic> _venue({
    required String id,
    required String name,
    required String city,
    required String address,
    required double rating,
    required int reviews,
    required List<String> activityIds,
  }) {
    final activities = activityIds
        .map((activityId) => {'activity': _activityById(activityId)})
        .toList();
    return {
      'id': id,
      'name': name,
      'title': name,
      'cityCode': city,
      'address': address,
      'location': address,
      'distance': 2.4,
      'distanceKm': 2.4,
      'rating': rating,
      'reviews': reviews,
      'reviewCount': reviews,
      'type': _venueTypeFor(activityIds),
      'category': _venueTypeFor(activityIds),
      'price': _priceForActivity(activityIds.first) / 100,
      'discount': '20% off',
      'imageUrls': [_image, _image, _image],
      'image': _image,
      'imagePath': _image,
      'activities': activities,
      'facilities': activityIds.indexed.map((entry) {
        final index = entry.$1 + 1;
        final activity = _activityById(entry.$2);
        return {
          'id': '${id}_court_$index',
          'venueId': id,
          'activityId': activity['id'],
          'name': '${activity['name']} Court $index',
          'type': _venueTypeFor([entry.$2]),
        };
      }).toList(),
      'offers': [
        {
          'id': '${id}_offer_1',
          'activityName':
              (activities.first['activity'] as Map<String, dynamic>)['name']
                  ?.toString(),
          'title': 'Save 20% today',
          'description': 'Use NEWUSER20 while reviewing your booking.',
        },
      ],
      'amenities': [
        {'name': 'Parking', 'iconAsset': AppAssets.parking, 'iconUrl': ''},
        {
          'name': 'Changing Room',
          'iconAsset': AppAssets.changingRoom,
          'iconUrl': '',
        },
        {
          'name': 'Drinking Water',
          'iconAsset': AppAssets.drinkingWater,
          'iconUrl': '',
        },
      ],
      'rules': [
        'Reach the venue 10 minutes before your slot.',
        'Carry non-marking shoes where required.',
        'Outside food is not allowed inside play areas.',
      ],
      'cancellationPolicy':
          'Free reschedule is allowed once. Cancellation refunds follow the time left before the slot starts.',
      'faqs': [
        {
          'question': 'Is equipment available?',
          'answer': 'Basic equipment is available at the venue reception.',
        },
        {
          'question': 'Can I add more players?',
          'answer': 'Yes, as long as the selected slot has capacity.',
        },
      ],
    };
  }

  static Map<String, dynamic> _activityById(String id) =>
      _activities.firstWhere((activity) => activity['id'] == id);

  static String _venueTypeFor(List<String> activityIds) {
    if (activityIds.any((id) => id.contains('football'))) return 'Turf';
    if (activityIds.any((id) => id.contains('cricket'))) return 'Cricket Nets';
    if (activityIds.any((id) => id.contains('pool') || id.contains('bowling'))) {
      return 'Table';
    }
    if (activityIds.length == 1) return 'Single';
    return 'Court';
  }

  static int _priceForActivity(String activityId) {
    if (activityId.contains('football') || activityId.contains('cricket')) {
      return 140000;
    }
    if (activityId.contains('bowling') || activityId.contains('pool')) {
      return 70000;
    }
    if (activityId.contains('gym') || activityId.contains('yoga')) {
      return 50000;
    }
    return 90000;
  }

  static Map<String, dynamic> _slotById(String slotId) {
    for (final venueData in _venues) {
      for (var day = 0; day < 10; day++) {
        final date = DateTime.now().add(Duration(days: day));
        final slots =
            availability(
                  venueData['id'].toString(),
                  date: _dateKey(date),
                )['items']
                as List;
        for (final slot in slots.cast<Map<String, dynamic>>()) {
          if (slot['slotId'] == slotId) {
            final facility = (venueData['facilities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((item) => item['id'] == slot['facilityId']);
            return {
              ...slot,
              'slot': {
                'id': slot['slotId'],
                'startsAt': slot['startsAt'],
                'endsAt': slot['endsAt'],
                'facility': {...facility, 'venue': venueData},
              },
            };
          }
        }
      }
    }
    return _firstFutureSlot();
  }

  static Map<String, dynamic> _firstFutureSlot() {
    final venueData = _venues.first;
    final slots =
        availability(
              venueData['id'].toString(),
              date: _dateKey(DateTime.now().add(const Duration(days: 1))),
            )['items']
            as List;
    return _slotById(
      slots.cast<Map<String, dynamic>>().first['slotId'].toString(),
    );
  }

  static Map<String, dynamic> _quote(
    Map<String, dynamic> slot,
    int quantity, {
    String? couponCode,
  }) {
    final subtotal =
        (int.tryParse('${slot['pricePaise']}') ?? 0) * quantity.clamp(1, 10);
    final fees = 4900;
    final discount = couponCode == null
        ? 0
        : couponCode.toUpperCase() == 'FLAT100'
        ? 10000
        : (subtotal * 0.2).round();
    final taxable = (fees + subtotal - discount).clamp(0, 99999999);
    final tax = (taxable * 0.18).round();
    return {
      'subtotal': subtotal,
      'fees': fees,
      'discount': discount,
      'tax': tax,
      'total': taxable + tax,
      'currency': 'INR',
    };
  }

  static Map<String, dynamic> _bookingFromAttempt(
    String bookingId,
    Map<String, dynamic> attempt,
  ) {
    final slot = _slotById(attempt['slotId'].toString());
    final quote = attempt['quote'] as Map<String, dynamic>;
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': bookingId,
      'publicCode':
          'ACT${bookingId.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}',
      'status': 'CONFIRMED',
      'startsAt': slot['startsAt'],
      'slot': slot['slot'],
      'attempt': {'id': attempt['id'], 'quantity': attempt['quantity']},
      'payments': const [],
      'refunds': const [],
      'totalPaise': quote['total'],
      'rescheduleCount': 0,
      'createdAt': now,
    };
  }

  static void _seedBookings() {
    if (_state.bookings.isNotEmpty) return;

    final upcomingSlot = _firstFutureSlot();
    final upcomingAttempt = {
      'id': 'attempt_seed_1',
      'slotId': upcomingSlot['slotId'],
      'quantity': 2,
      'quote': _quote(upcomingSlot, 2),
    };
    _state.bookings['booking_seed_upcoming'] = _bookingFromAttempt(
      'booking_seed_upcoming',
      upcomingAttempt,
    );

    final completed = _bookingFromAttempt(
      'booking_seed_completed',
      upcomingAttempt,
    );
    completed
      ..['id'] = 'booking_seed_completed'
      ..['publicCode'] = 'ACT900201'
      ..['status'] = 'COMPLETED'
      ..['startsAt'] = DateTime.now()
          .subtract(const Duration(days: 3))
          .toUtc()
          .toIso8601String();
    (completed['slot'] as Map<String, dynamic>)['endsAt'] = DateTime.now()
        .subtract(const Duration(days: 3, hours: -1))
        .toUtc()
        .toIso8601String();
    _state.bookings['booking_seed_completed'] = completed;

    final cancelled = _bookingFromAttempt(
      'booking_seed_cancelled',
      upcomingAttempt,
    );
    cancelled
      ..['id'] = 'booking_seed_cancelled'
      ..['publicCode'] = 'ACT900202'
      ..['status'] = 'CANCELLED'
      ..['startsAt'] = DateTime.now()
          .subtract(const Duration(days: 1))
          .toUtc()
          .toIso8601String()
      ..['refunds'] = [
        {
          'id': 'refund_seed_cancelled',
          'amountPaise': 90000,
          'status': 'PROCESSED',
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 18))
              .toIso8601String(),
        },
      ];
    _state.bookings['booking_seed_cancelled'] = cancelled;
  }

  static int _priceForHour(int hour) {
    if (hour >= 18) return 140000;
    if (hour >= 16) return 120000;
    return 90000;
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

}

class _MockUserState {
  _MockUserState(String userId)
    : profile = {
        'id': userId,
        'name': '',
        'email': '',
        'phone': '',
        'phoneE164': '',
      };

  int attemptCounter = 1000;
  int paymentCounter = 2000;
  int bookingCounter = 3000;
  int reviewCounter = 4000;

  final Map<String, dynamic> profile;
  final Map<String, Map<String, dynamic>> attempts = {};
  final Map<String, Map<String, dynamic>> payments = {};
  final Map<String, Map<String, dynamic>> bookings = {};
  final Map<String, Map<String, dynamic>> reviews = {};
  final Set<String> savedVenueIds = {};
  final Set<String> readNotificationIds = {};
  final Set<String> deletedNotificationIds = {};
}
