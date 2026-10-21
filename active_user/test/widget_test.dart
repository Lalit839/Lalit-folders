import 'package:activ_user_app/features/my_bookings/presentation/widgets/booking_card.dart';
import 'package:activ_user_app/features/my_bookings/presentation/widgets/booking_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activ_user_app/features/home/presentation/widgets/location_permission_bottom_sheet.dart';

void main() {
  testWidgets(
    'LocationPermissionBottomSheet renders GPS Disabled state correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPermissionBottomSheet(
              state: LocationState.gpsDisabled,
              onAllowLocationAccess: () {},
              onEnableGPS: () {},
              onOpenSettings: () {},
              onSelectManualLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Location Services Disabled'), findsOneWidget);
      expect(find.text('Enable GPS'), findsOneWidget);
      expect(find.text('Select location manually'), findsOneWidget);
    },
  );

  testWidgets(
    'LocationPermissionBottomSheet renders Permission Denied state correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPermissionBottomSheet(
              state: LocationState.permissionDenied,
              onAllowLocationAccess: () {},
              onEnableGPS: () {},
              onOpenSettings: () {},
              onSelectManualLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Allow Location Access'), findsOneWidget);
      expect(find.text('Allow Access'), findsOneWidget);
      expect(find.text('Select location manually'), findsOneWidget);
    },
  );

  testWidgets('BookingCard renders details correctly with status tag', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BookingCard(
            title: 'Dugout - Turf and Cafe',
            sport: 'Football',
            location: 'Robot square, Indore',
            date: '02 June',
            time: '3-4 pm',
            status: 'Rescheduled',
          ),
        ),
      ),
    );

    expect(find.text('Dugout - Turf and Cafe'), findsOneWidget);
    expect(find.text('Football | Robot square, Indore'), findsOneWidget);
    expect(find.text('02 June'), findsOneWidget);
    expect(find.text('3-4 pm'), findsOneWidget);
    expect(find.text('Rescheduled'), findsOneWidget);
  });

  testWidgets(
    'BookingTabBar renders and handles index tap selection correctly',
    (WidgetTester tester) async {
      int selectedIdx = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: BookingTabBar(
                  selectedIndex: selectedIdx,
                  onTabChanged: (index) {
                    setState(() {
                      selectedIdx = index;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(selectedIdx, 1);
    },
  );
}
