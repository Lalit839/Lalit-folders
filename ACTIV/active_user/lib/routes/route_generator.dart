import 'package:flutter/material.dart';
import 'package:activ_user_app/features/auth/presentation/screens/login_screen.dart';
import 'package:activ_user_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:activ_user_app/features/auth/presentation/screens/user_name_screen.dart';
import 'package:activ_user_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:activ_user_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:activ_user_app/features/edit_profile/presentation/screens/edit_profile_screen.dart';
import 'package:activ_user_app/features/notifications/presentation/screens/notification_screen.dart';
import 'package:activ_user_app/features/notifications/presentation/screens/notification_permission_screen.dart';
import 'package:activ_user_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:activ_user_app/features/payment/presentation/screens/payment_success_screen.dart';
import 'package:activ_user_app/features/payment/presentation/screens/payment_failed_screen.dart';
import 'package:activ_user_app/features/location/presentation/screens/set_location_screen.dart';
import 'package:activ_user_app/features/location/presentation/screens/location_permission_screen.dart';
import 'package:activ_user_app/features/location/presentation/screens/out_of_bounds_screen.dart';
import 'package:activ_user_app/features/review_booking/coupons/presentation/screens/coupons_screen.dart';
import 'package:activ_user_app/features/location/presentation/screens/area_search_screen.dart';
import 'package:activ_user_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:activ_user_app/features/venue/presentation/screens/venue_search_screen.dart';
import 'package:activ_user_app/features/venue/presentation/screens/venue_filter_screen.dart';
import 'package:activ_user_app/features/venue_details/presentation/screens/venue_details_screen.dart';
import 'package:activ_user_app/features/slot_booking/presentation/screens/book_your_slot_screen.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/features/my_bookings/presentation/screens/bookings_screen.dart';
import 'package:activ_user_app/features/booking_details/presentation/screens/booking_details_screen.dart';
import 'package:activ_user_app/features/reschedule_booking/presentation/screens/reschedule_booking_screen.dart';
import 'package:activ_user_app/features/cancel_booking/presentation/screens/cancellation_summary_screen.dart';
import 'package:activ_user_app/features/preferences/presentation/screens/preferences_screen.dart';
import 'package:activ_user_app/features/booking_policies/presentation/screens/booking_policies_screen.dart';
import 'package:activ_user_app/features/help_support/presentation/screens/help_support_screen.dart';
import 'package:activ_user_app/features/legal/presentation/screens/legal_screen.dart';
import 'package:activ_user_app/features/privacy_policy/presentation/screens/privacy_policy_screen.dart';
import 'package:activ_user_app/features/terms_conditions/presentation/screens/terms_conditions_screen.dart';
import 'package:activ_user_app/features/rate_activ/presentation/screens/rate_activ_screen.dart';
import 'package:activ_user_app/features/faqs/presentation/screens/faqs_screen.dart';
import 'package:activ_user_app/features/delete_account/presentation/screens/delete_account_screen.dart';
import 'package:activ_user_app/features/rate_activ/presentation/screens/review_history_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.otp:
        final mobileNumber = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OTPScreen(mobileNumber: mobileNumber),
          settings: settings,
        );
      case AppRoutes.userName:
        return MaterialPageRoute(
          builder: (_) => const UserNameScreen(),
          settings: settings,
        );
      case AppRoutes.dashboard:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final initialIndex = args['initialIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(initialIndex: initialIndex),
          settings: settings,
        );
      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );
      case AppRoutes.paymentSuccess:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final paymentId = args['paymentId'] as String? ?? 'pay_MOCK12345';
        final amount = (args['amount'] as num? ?? 1218.82).toDouble();
        return MaterialPageRoute(
          builder: (_) =>
              PaymentSuccessScreen(paymentId: paymentId, amount: amount),
          settings: settings,
        );
      case AppRoutes.paymentFailed:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final message = args['message'] as String? ?? 'Payment cancelled';
        final amount = (args['amount'] as num? ?? 1218.82).toDouble();
        return MaterialPageRoute(
          builder: (_) =>
              PaymentFailedScreen(errorMessage: message, amount: amount),
          settings: settings,
        );
      case AppRoutes.setLocation:
        return MaterialPageRoute(
          builder: (_) => const SetLocationScreen(),
          settings: settings,
        );
      case AppRoutes.locationPermission:
        return MaterialPageRoute(
            builder: (_) => const LocationPermissionScreen());
      case AppRoutes.notificationPermission:
        return MaterialPageRoute(
            builder: (_) => const NotificationPermissionScreen());
      case AppRoutes.areaSearch:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final city = args['city'] as String? ?? 'Selected city';
        final areas = args['areas'] as List<String>? ?? [];
        return MaterialPageRoute(
          builder: (_) => AreaSearchScreen(city: city, areas: areas),
          settings: settings,
        );
      case AppRoutes.outOfBounds:
        return MaterialPageRoute(
          builder: (_) => const OutOfBoundsScreen(),
          settings: settings,
        );
      case AppRoutes.coupons:
        return MaterialPageRoute(
          builder: (_) => const CouponsScreen(),
          settings: settings,
        );
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case AppRoutes.venueSearch:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final initialSport = args['selectedSport'] as String?;
        final cityCode = args['cityCode'] as String?;
        final latitude = (args['latitude'] as num?)?.toDouble();
        final longitude = (args['longitude'] as num?)?.toDouble();
        final radiusKm = (args['radiusKm'] as num?)?.toDouble();
        final locationLabel = args['locationLabel'] as String?;
        return MaterialPageRoute(
          builder: (_) => VenueSearchScreen(
            initialSport: initialSport,
            cityCode: cityCode,
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
            locationLabel: locationLabel,
          ),
          settings: settings,
        );
      case AppRoutes.venueFilter:
        return MaterialPageRoute(
          builder: (_) => const VenueFilterScreen(),
          settings: settings,
        );
      case AppRoutes.venueDetails:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => VenueDetailsScreen(venueId: args['venueId'] as String?),
          settings: settings,
        );
      case AppRoutes.bookSlot:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final initialActivity = args['activity'] as String?;
        return MaterialPageRoute(
           builder: (_) => BookYourSlotScreen(initialActivity: initialActivity, venueId: args['venueId'] as String?, bookingId: args['bookingId'] as String?),
          settings: settings,
        );
      case AppRoutes.bookings:
        return MaterialPageRoute(
          builder: (_) => const BookingsScreen(),
          settings: settings,
        );
      case AppRoutes.bookingDetails:
        return MaterialPageRoute(
          builder: (_) => const BookingDetailsScreen(),
          settings: settings,
        );
      case AppRoutes.rescheduleBooking:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final isCancelMode = args['isCancelMode'] as bool? ?? false;
        final bookingId = args['bookingId'] as String?;
        return MaterialPageRoute(
          builder: (_) => RescheduleBookingScreen(
            isCancelMode: isCancelMode,
            bookingId: bookingId,
          ),
          settings: settings,
        );
      case AppRoutes.cancellationSummary:
        return MaterialPageRoute(
          builder: (_) => const CancellationSummaryScreen(),
          settings: settings,
        );
      case AppRoutes.preferences:
        return MaterialPageRoute(
          builder: (_) => const PreferencesScreen(),
          settings: settings,
        );
      case AppRoutes.bookingPolicies:
        return MaterialPageRoute(
          builder: (_) => const BookingPoliciesScreen(),
          settings: settings,
        );
      case AppRoutes.helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );
      case AppRoutes.legal:
        return MaterialPageRoute(
          builder: (_) => const LegalScreen(),
          settings: settings,
        );
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );
      case AppRoutes.termsConditions:
        return MaterialPageRoute(
          builder: (_) => const TermsConditionsScreen(),
          settings: settings,
        );
      case AppRoutes.rateActiv:
        return MaterialPageRoute(
          builder: (_) => const RateActivScreen(),
          settings: settings,
        );
      case AppRoutes.faqs:
        return MaterialPageRoute(
          builder: (_) => const FaqsScreen(),
          settings: settings,
        );
      case AppRoutes.deleteAccount:
        return MaterialPageRoute(
          builder: (_) => const DeleteAccountScreen(),
          settings: settings,
        );
      case AppRoutes.reviewHistory:
        return MaterialPageRoute(
          builder: (_) => const ReviewHistoryScreen(),
          settings: settings,
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}
