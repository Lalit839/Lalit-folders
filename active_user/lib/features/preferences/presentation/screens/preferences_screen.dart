import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _pushNotifications = true;
  bool _bookingUpdates = false;
  bool _matchReminders = false;
  bool _allowLocation = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await ActivApiClient.instance.getProfile();
      final preferences = profile['preferences'];
      if (preferences is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _pushNotifications =
              preferences['pushNotifications'] as bool? ?? _pushNotifications;
          _bookingUpdates =
              preferences['bookingUpdates'] as bool? ?? _bookingUpdates;
          _matchReminders =
              preferences['matchReminders'] as bool? ?? _matchReminders;
          _allowLocation =
              preferences['allowLocation'] as bool? ?? _allowLocation;
        });
      }
    } on ActivApiException {
      // Keep defaults when preferences cannot be loaded.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _currentPreferences() => {
        'pushNotifications': _pushNotifications,
        'bookingUpdates': _bookingUpdates,
        'matchReminders': _matchReminders,
        'allowLocation': _allowLocation,
      };

  Future<void> _update(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'pushNotifications':
          _pushNotifications = value;
          break;
        case 'bookingUpdates':
          _bookingUpdates = value;
          break;
        case 'matchReminders':
          _matchReminders = value;
          break;
        case 'allowLocation':
          _allowLocation = value;
          break;
      }
    });
    try {
      await ActivApiClient.instance
          .updateProfile(preferences: _currentPreferences());
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preference: ${error.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Preferences'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubSectionHeader(title: 'Notification Settings'),
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.blackColor2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          _buildSwitchItem(
                            title: 'Push Notifications',
                            description:
                                'Receive booking updates, reminders, and important alerts.',
                            value: _pushNotifications,
                            onChanged: (val) =>
                                _update('pushNotifications', val),
                          ),
                          const SizedBox(height: 24),
                          _buildSwitchItem(
                            title: 'Booking Updates',
                            description:
                                'Get notified about booking confirmations, cancellations, and reschedules.',
                            value: _bookingUpdates,
                            onChanged: (val) => _update('bookingUpdates', val),
                          ),
                          const SizedBox(height: 24),
                          _buildSwitchItem(
                            title: 'Match Reminders',
                            description:
                                'Receive reminders before your upcoming matches and sessions.',
                            value: _matchReminders,
                            onChanged: (val) => _update('matchReminders', val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // App Permissions
                    SubSectionHeader(title: 'App Permissions'),
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.blackColor2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: _buildSwitchItem(
                        title: 'Allow Location Access',
                        description:
                            'Help us find nearby sports venues and provide location-based recommendations.',
                        value: _allowLocation,
                        onChanged: (val) => _update('allowLocation', val),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bold(title, color: AppColors.textPrimary, fontSize: 18),
              const SizedBox(height: 2),
              AppText.small(
                description,
                color: AppColors.grey99,
                fontSize: 12,
                height: 1.4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.primary,
            thumbColor: value ? AppColors.black : AppColors.greyBorder,
            inactiveTrackColor: AppColors.lightGreyBorder,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}