import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _handleAllowNotifications() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    // Note: Firebase/push notifications are not configured for this demo build,
    // so we do NOT show a fake OS permission dialog or a fake success. Instead we
    // inform the user honestly and continue into the app.
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Push notifications aren\'t available in this demo build yet.',
          ),
        ),
      );
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
  }

  Widget _buildFeatureItem(String iconPath, String label, Color itemColor) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.yellowDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppSvg(iconPath, width: 14, height: 14, color: itemColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              label,
              color: AppColors.white,
              fontSize: 12,
              maxLines: 2,
            ),
          ),
        ],
      ),
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
              AppAssets.notificationBanner,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
                        Icons.notifications,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Title
                  Center(
                    child: AppText.bold(
                      'Stay updated',
                      color: AppColors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Center(
                    child: AppText.small(
                      'Get notified about important updates so you never miss a game.',
                      color: AppColors.grey99,
                      textAlign: TextAlign.center,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Features Grid
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildFeatureItem(
                              AppAssets.reschedule,
                              'Booking Confirmations',
                              AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            _buildFeatureItem(
                              AppAssets.calendar,
                              'Upcoming Sessions',
                              AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildFeatureItem(
                              AppAssets.notification,
                              'Venue Updates',
                              AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            _buildFeatureItem(
                              AppAssets.fire,
                              'ACTIV Streak Reminders',
                              AppColors.errorRed2,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Allow Notifications Button
                  AppButton(
                    title: 'Allow notifications',
                    showArrow: true,
                    isLoading: _isLoading,
                    onTap: _handleAllowNotifications,
                  ),
                  const SizedBox(height: 16),

                  // Not Now Button
                  AppButton(
                    title: 'Not Now',
                    showArrow: false,
                    backgroundColor: Colors.transparent,
                    textColor: AppColors.greyBorder,
                    borderColor: AppColors.lightGreyBorder,
                    onTap: _navigateToDashboard,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
