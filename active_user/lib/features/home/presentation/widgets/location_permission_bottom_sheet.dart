import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';

enum LocationState {
  checking,
  allowed,
  gpsDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  manual,
}

void showLocationPermissionBottomSheet({
  required BuildContext context,
  required LocationState state,
  required VoidCallback onAllowLocationAccess,
  required VoidCallback onEnableGPS,
  required VoidCallback onOpenSettings,
  required VoidCallback onSelectManualLocation,
}) {
  if (state == LocationState.checking ||
      state == LocationState.allowed ||
      state == LocationState.manual) {
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LocationPermissionBottomSheet(
      state: state,
      onAllowLocationAccess: () {
        Navigator.pop(context);
        onAllowLocationAccess();
      },
      onEnableGPS: () {
        Navigator.pop(context);
        onEnableGPS();
      },
      onOpenSettings: () {
        Navigator.pop(context);
        onOpenSettings();
      },
      onSelectManualLocation: () {
        Navigator.pop(context);
        onSelectManualLocation();
      },
    ),
  );
}

class LocationPermissionBottomSheet extends StatelessWidget {
  final LocationState state;
  final VoidCallback onAllowLocationAccess;
  final VoidCallback onEnableGPS;
  final VoidCallback onOpenSettings;
  final VoidCallback onSelectManualLocation;

  const LocationPermissionBottomSheet({
    super.key,
    required this.state,
    required this.onAllowLocationAccess,
    required this.onEnableGPS,
    required this.onOpenSettings,
    required this.onSelectManualLocation,
  });

  @override
  Widget build(BuildContext context) {
    String titleText = '';
    String subtitleText = '';
    String buttonTitle = '';
    VoidCallback primaryAction = () {};
    IconData sheetIcon = Icons.location_on_rounded;

    switch (state) {
      case LocationState.gpsDisabled:
        titleText = 'Location Services Disabled';
        subtitleText = 'Please enable GPS to find venues around you easily.';
        buttonTitle = 'Enable GPS';
        primaryAction = onEnableGPS;
        sheetIcon = Icons.gps_off_rounded;
        break;
      case LocationState.permissionDenied:
        titleText = 'Allow Location Access';
        subtitleText =
            'Enable location to discover the best sports venues nearby.';
        buttonTitle = 'Allow Access';
        primaryAction = onAllowLocationAccess;
        sheetIcon = Icons.location_on_rounded;
        break;
      case LocationState.permissionPermanentlyDenied:
        titleText = 'Location Permission Denied';
        subtitleText =
            'Please enable location access in settings to find venues.';
        buttonTitle = 'Open Settings';
        primaryAction = onOpenSettings;
        sheetIcon = Icons.settings_suggest_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGreyBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Icon Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(sheetIcon, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 24),

          // Title
          AppText(
            titleText,
            color: AppColors.textPrimary,
            fontSize: 22,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          AppText(
            subtitleText,
            color: AppColors.grey,
            fontSize: 16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Primary Action
          AppButton(title: buttonTitle, onTap: primaryAction, height: 54),
          const SizedBox(height: 16),

          // Secondary Action
          GestureDetector(
            onTap: onSelectManualLocation,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Select location manually',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
