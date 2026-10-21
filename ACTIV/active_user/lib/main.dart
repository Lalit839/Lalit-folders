import 'package:flutter/material.dart';
import 'package:activ_user_app/core/theme/app_theme.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/services/push_service.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/routes/route_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/core/config/env_config.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Deep-link (notification tap) → route. Payload from the ACTIV backend:
///   {"type": "venue", "venueId": "..."} | {"type": "booking", "bookingId": "..."}
void _handleNotificationTap(Map<String, dynamic> data) {
  if (data.isEmpty) return;
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  final type = data['type'];
  WidgetsBinding.instance.addPostFrameCallback((_) {
    nav.popUntil((route) => route.isFirst);
    // VenueDetailsScreen takes a venueId; the bookings list screen is the
    // entry point for booking notifications (details are fetched by the app).
    if (type == 'venue' && data['venueId'] != null) {
      nav.pushNamed(
        AppRoutes.venueDetails,
        arguments: {'venueId': data['venueId']},
      );
    } else if (type == 'booking') {
      nav.pushNamed(AppRoutes.bookings);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ActivApiClient.navigatorKey = navigatorKey;
  await EnvConfig.init();
  await SharedPrefService.init();
  PushService.instance.onNotificationTap = _handleNotificationTap;
  await PushService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ACTIV',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SafeArea(
            top: false, // We want the status bar to be edge-to-edge
            left: false,
            right: false,
            child: child!,
          ),
        );
      },
    );
  }
}
