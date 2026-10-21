import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/services/location_service.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:activ_user_app/features/home/presentation/widgets/location_permission_bottom_sheet.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _handleShareLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isGpsEnabled = await LocationService.isLocationEnabled();
      if (!isGpsEnabled) {
        _showPermissionPopup(LocationState.gpsDisabled);
        return;
      }

      var permission = await LocationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await LocationService.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionPopup(LocationState.permissionDenied);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPopup(LocationState.permissionPermanentlyDenied);
        return;
      }

      // Permission granted, GPS enabled. Proceed to dashboard.
      _navigateToDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionPopup(LocationState state) {
    if (!mounted) return;
    showLocationPermissionBottomSheet(
      context: context,
      state: state,
      onAllowLocationAccess: () async {
        _handleShareLocation(); // retry
      },
      onEnableGPS: () async {
        await LocationService.openLocationSettings();
      },
      onOpenSettings: () async {
        await LocationService.openAppSettings();
      },
      onSelectManualLocation: () {
        _navigateToDashboard();
      },
    );
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.notificationPermission,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.asset(
              AppAssets.locationBanner,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback just in case the asset is missing
                return Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: AppText.bold(
                      'Find activities near you',
                      color: AppColors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: AppText.small(
                      'Share your location to discover venues and games closest to you.',
                      color: AppColors.grey99,
                      textAlign: TextAlign.center,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Share Location Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppButton(
                    title: 'Share location',
                    showArrow: true,
                    isLoading: _isLoading,
                    onTap: _handleShareLocation,
                  ),
                ),
                const SizedBox(height: 16),

                // Maybe Later Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppButton(
                    title: 'Maybe Later',
                    showArrow: false,
                    backgroundColor: Colors.transparent,
                    textColor: AppColors.greyBorder,
                    borderColor: AppColors.lightGreyBorder,
                    onTap: _navigateToDashboard,
                  ),
                ),

                const SizedBox(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
