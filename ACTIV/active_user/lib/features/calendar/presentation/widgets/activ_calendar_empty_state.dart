import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';

class ActivCalendarEmptyState extends StatelessWidget {
  final VoidCallback onShare;
  
  const ActivCalendarEmptyState({super.key, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration
          Image.asset(
            AppAssets.calendarEmpty,
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          
          // Text
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter', // Assuming standard app font
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: 'Your journey '),
                TextSpan(
                  text: 'starts now!',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AppText.medium(
            'Complete Your First Activity And\nStart Your Streak.',
            color: AppColors.grey99,
            fontSize: 12,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.venueSearch);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  AppText.bold(
                    'Find an Activity',
                    color: AppColors.black,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          // Share Button
          const SizedBox(height: 16),
          InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.blackColor2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  AppText.bold(
                    'Share Your Activity',
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
