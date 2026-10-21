import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/features/rate_activ/presentation/widgets/review_success_bottom_sheet.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isSubmitting = false;

  Future<void> _requestDeletion() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ActivApiClient.instance.requestDeletion();
      if (!mounted) return;
      showReviewSuccessBottomSheet(
        context: context,
        title: 'Request Submitted!',
        description:
            'Your account deletion request will be processed within 30 days.\nYou can still access your account until then.',
        onDone: () {
          Navigator.of(context).pop(); // pop the bottom sheet
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        },
      );
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Delete Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                color: AppColors.blackColor2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bold(
                      'Delete your ACTIV account?',
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    const SizedBox(height: 12),
                    AppText.small(
                      'All data associated with your account including your '
                      'profile, bookings, photos, and reviews will be '
                      'permanently deleted after 30 days. Once permanently '
                      'deleted, this action cannot be reversed and your data '
                      'cannot be recovered.',
                      color: AppColors.grey99,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AppButton(
                title: 'Delete My Account',
                backgroundColor: AppColors.errorRed,
                textColor: AppColors.white,
                isLoading: _isSubmitting,
                showArrow: true,
                onTap: _requestDeletion,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}