import 'dart:async';

import 'package:activ_user_app/features/auth/presentation/screens/login_screen.dart';
import 'package:activ_user_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:activ_user_app/features/saved_venues/presentation/state/saved_venues_provider.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _startNavigationDelay();
  }

  void _startNavigationDelay() {
    unawaited(_routeFromStoredSession());
  }

  Future<void> _routeFromStoredSession() async {
    final showOnboarding = !SharedPrefService.isOnboardingCompleted;
    final isLoggedIn = SharedPrefService.isLoggedIn;

    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;

    final Widget nextScreen;
    if (showOnboarding) {
      nextScreen = const OnboardingScreen();
    } else if (isLoggedIn) {
      nextScreen = const DashboardScreen();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );

    if (!showOnboarding && isLoggedIn) {
      unawaited(_syncStoredSession());
    }
  }

  Future<void> _syncStoredSession() async {
    try {
      final profile = await ActivApiClient.instance.getProfile();
      final name = profile['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        await SharedPrefService.setUserName(name);
        await SharedPrefService.setLoggedIn(true);
      }
      final email = profile['email']?.toString();
      if (email != null && email.isNotEmpty) {
        await SharedPrefService.setUserEmail(email);
      }
      final photo = profile['profilePhoto']?.toString();
      if (photo != null && photo.isNotEmpty) {
        await SharedPrefService.setProfilePhotoBase64(photo);
      }
      unawaited(_primeSavedVenues());
    } catch (_) {
      // Keep startup moving. Auth failures are handled by the API client, and
      // network timeouts should not trap users on the splash screen.
    }
  }

  Future<void> _primeSavedVenues() async {
    try {
      final saved = await ActivApiClient.instance.getSavedVenues();
      final venues = saved.whereType<Map<String, dynamic>>().map((item) {
        final venue = item['venue'] as Map<String, dynamic>? ?? item;
        final imageUrls = (venue['imageUrls'] as List?) ?? const [];
        return <String, dynamic>{
          'id': venue['id'],
          'title': venue['name'],
          'location': venue['cityCode']?.toString() ?? '',
          'imagePath': imageUrls.isNotEmpty ? imageUrls.first.toString() : '',
          'distance': venue['distance']?.toString() ?? '',
          'discount': venue['discount']?.toString() ?? '',
          'rating': (venue['rating'] as num?)?.toDouble() ?? 0.0,
          'reviews': (venue['reviewCount'] as num?)?.toInt() ?? 0,
          'isAvailable': true,
        };
      }).toList();
      ref.read(savedVenuesProvider.notifier).setVenues(venues);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors
          .black, // Ensure this perfectly matches the GIF's background color
      body: Center(
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                0.20, // 20% from top begins full opacity
                0.80, // 20% from bottom begins fade to transparent
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Image.asset(AppAssets.splashGif, fit: BoxFit.fitWidth),
        ),
      ),
    );
  }
}
