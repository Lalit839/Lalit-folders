import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_strings.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class OutOfBoundsScreen extends StatelessWidget {
  const OutOfBoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing concentric circles with location pin
              Center(child: AppSvg(AppAssets.outOfBonds)),
              const SizedBox(height: 34),

              AppText.medium(
                AppStrings.outOfBoundsTitle,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              const SizedBox(height: 12),

              AppText.medium(
                AppStrings.outOfBoundsSubtitle,
                color: AppColors.primary,
                fontSize: 26,
              ),
              const SizedBox(height: 4),

              AppText.small(
                AppStrings.outOfBoundsDescription,
                color: AppColors.grey99,
                fontSize: 16,
              ),

              const SizedBox(height: 55),

              // Buttons
              AppButton(
                title: AppStrings.outOfBoundsButtonText,
                onTap: () {
                  Navigator.pop(context); // Go back to SetLocationScreen
                },
                backgroundColor: AppColors.lightGrey,
                textColor: AppColors.primary,
                width: 246,
                borderRadius: 48,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await SharedPrefService.setOutOfBoundsNotifyMe(true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Got it! We will notify you once ACTIV expands to this area.',
                      ),
                    ),
                  );
                },
                child: AppText.small(
                  AppStrings.outOfBoundsNotifyText,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
