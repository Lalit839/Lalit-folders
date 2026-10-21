import 'package:activ_user_app/core/network/mock_activ_data.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefService.resetForTesting();
    await SharedPrefService.init();
    await SharedPrefService.clear();
    MockActivData.resetAll();
  });

  test('shared preferences isolate private cache by authenticated user id', () async {
    await SharedPrefService.setCurrentUserId('user-a');
    await SharedPrefService.setUserName('Asha Player');
    await SharedPrefService.setUserEmail('asha@example.test');
    await SharedPrefService.setSavedVenuesCache('[{"id":"venue_a"}]');

    await SharedPrefService.setCurrentUserId('user-b');
    expect(SharedPrefService.userName, isNull);
    expect(SharedPrefService.userEmail, isNull);
    expect(SharedPrefService.savedVenuesCache, isNull);

    await SharedPrefService.setUserName('Bharat Player');

    await SharedPrefService.setCurrentUserId('user-a');
    expect(SharedPrefService.userName, 'Asha Player');
    expect(SharedPrefService.userEmail, 'asha@example.test');
    expect(SharedPrefService.savedVenuesCache, '[{"id":"venue_a"}]');

    await SharedPrefService.setCurrentUserId('user-b');
    expect(SharedPrefService.userName, 'Bharat Player');
    expect(SharedPrefService.userEmail, isNull);
  });

  test('mock bookings, favorites, notifications, and reviews are user scoped', () {
    MockActivData.startSession('user-a');
    MockActivData.saveVenue('venue_box_01');
    final userASlot = (MockActivData.availability('venue_box_01')['items'] as List)
        .cast<Map<String, dynamic>>()
        .first;
    final userAAttempt = MockActivData.createBookingAttempt(
      userASlot['slotId'].toString(),
      2,
    );
    final userAPayment = MockActivData.createPaymentOrder(
      userAAttempt['id'].toString(),
    );
    MockActivData.markNotificationRead('notif_offer');
    MockActivData.submitReview(
      userAPayment['bookingId'].toString(),
      rating: 5,
      body: 'Great session.',
    );

    expect(MockActivData.savedVenues(), hasLength(1));
    expect(
      MockActivData.bookings()['items'],
      contains(predicate<Map<String, dynamic>>(
        (booking) => booking['id'] == userAPayment['bookingId'],
      )),
    );
    expect(MockActivData.reviewHistory(), hasLength(1));

    MockActivData.startSession('user-b');
    expect(MockActivData.savedVenues(), isEmpty);
    expect(MockActivData.reviewHistory(), isEmpty);
    expect(
      MockActivData.bookings()['items'],
      isNot(contains(predicate<Map<String, dynamic>>(
        (booking) => booking['id'] == userAPayment['bookingId'],
      ))),
    );
    expect(
      MockActivData.notifications().firstWhere(
        (item) => item['id'] == 'notif_offer',
      )['isRead'],
      isFalse,
    );

    MockActivData.startSession('user-a');
    expect(MockActivData.savedVenues(), hasLength(1));
    expect(MockActivData.reviewHistory(), hasLength(1));
    expect(
      MockActivData.notifications().firstWhere(
        (item) => item['id'] == 'notif_offer',
      )['isRead'],
      isTrue,
    );
  });
}
