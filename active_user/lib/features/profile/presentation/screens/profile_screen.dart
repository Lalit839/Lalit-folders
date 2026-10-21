import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/profile/presentation/widgets/logout_button.dart';
import 'package:activ_user_app/features/profile/presentation/widgets/profile_user_info.dart';
import 'package:activ_user_app/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/services/push_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/features/saved_venues/presentation/state/saved_venues_provider.dart';

class ProfileMenuModel {
  final String title;
  final String icon;
  final String route;

  const ProfileMenuModel({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

Future<void> _loadProfile() async {
    try {
      final profile = await ActivApiClient.instance.getProfile();
      final email = profile['email']?.toString();
      if (email != null && email.isNotEmpty) {
        SharedPrefService.setUserEmail(email);
      }
      final photo = profile['profilePhoto']?.toString();
      if (photo != null && photo.isNotEmpty) {
        SharedPrefService.setProfilePhotoBase64(photo);
      }
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } on ActivApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data-driven approach for menus
    final profileMenus = [
      ProfileMenuModel(
        title: 'My Bookings',
        icon: AppAssets.navBookings,
        route: AppRoutes.bookings,
      ),
      ProfileMenuModel(
        title: 'Preferences',
        icon: AppAssets.preferencesIcon,
        route: AppRoutes.preferences,
      ),
      ProfileMenuModel(
        title: 'Booking Policies',
        icon: AppAssets.venueRules,
        route: AppRoutes.bookingPolicies,
      ),
      ProfileMenuModel(
        title: 'Help & Support',
        icon: AppAssets.supportAlt,
        route: AppRoutes.helpSupport,
      ),
      ProfileMenuModel(
        title: 'Legal',
        icon: AppAssets.legalIcon,
        route: AppRoutes.legal,
      ),
      ProfileMenuModel(
        title: 'Rate ACTIV',
        icon: AppAssets.rating,
        route: AppRoutes.rateActiv,
      ),
      ProfileMenuModel(
        title: 'FAQs',
        icon: AppAssets.faqs,
        route: AppRoutes.faqs,
      ),
      ProfileMenuModel(
        title: 'ACTIV Merch',
        icon: AppAssets.activMerch,
        route: '',
      ),
    ];

  

    final String userName = _profile?['name'] as String? ?? SharedPrefService.userName ?? 'ACTIV User';
    final String userPhone = _profile?['phoneE164'] as String? ?? '';
    const String appVersion = 'Version 1.0.1';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // 1. User Info Section
              ProfileUserInfo(
                userName: _isLoading ? 'Loading profile...' : userName,
                userPhone: userPhone,
                userEmail: SharedPrefService.userEmail,
                profilePhotoBase64: SharedPrefService.profilePhotoBase64,
                onEditProfile: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  if (mounted) _loadProfile();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppText.small(_error!, color: AppColors.errorRed, textAlign: TextAlign.center),
              ],

              // 3. Menu List Section (data-driven with separators)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profileMenus.length,
                separatorBuilder: (context, index) =>
                    AppDivider(verticalPadding: 0),
                itemBuilder: (context, index) {
                  final menu = profileMenus[index];
                  // Wrap with a top divider only for the very first item to match visual mock
                  Widget item = ProfileMenuItem(
                    title: menu.title,
                    iconPath: menu.icon,
                    onTap: () async {
                      if (menu.title == 'ACTIV Merch') {
                        final Uri url = Uri.parse('https://activmerch.com/');
                        if (!await launchUrl(url)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not launch website'),
                              ),
                            );
                          }
                        }
                      } else if (menu.route.isNotEmpty) {
                        Navigator.of(context).pushNamed(menu.route);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(
                              'Navigation to ${menu.title} is coming soon!',
                              color: AppColors.white,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );

                  return item;
                },
              ),
              const SizedBox(height: 36),

              // 4. Logout Section
              LogoutButton(onTap: () => _showLogoutBottomSheet(context)),
              const SizedBox(height: 40),

              // 5. Footer Section
              Center(
                child: Column(
                  children: [
                    const Opacity(
                      opacity: 0.3,
                      child: AppLogo(width: 80, height: 80),
                    ),
                    const SizedBox(height: 8),
                    AppText(appVersion, color: AppColors.grey99, fontSize: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutBottomSheet(BuildContext context) {
    showConfirmationBottomSheet(
      context: context,
      iconPath: AppAssets.logout,
      iconColor: AppColors.errorRed,
      title: 'Confirm Logout',
      description: 'Are you sure you want to logout from ACTIV?',
      primaryButtonTitle: 'Logout',
      primaryButtonColor: AppColors.errorRed,
onPrimaryButtonTap: () async {
         try {
           await ActivApiClient.instance.logout();
         } on ActivApiException {
           // Continue local logout when the session is already invalid.
         }
         await PushService.instance.unregister();
         await ActivApiClient.instance.clearLocalSession();
         ref.read(savedVenuesProvider.notifier).clear();
         if (!context.mounted) return;
         Navigator.pop(context); // close bottom sheet
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      },
    );
  }
}
