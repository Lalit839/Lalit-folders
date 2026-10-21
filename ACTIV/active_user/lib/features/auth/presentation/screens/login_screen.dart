import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_fonts.dart';
import 'package:activ_user_app/core/constants/app_strings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/auth/presentation/widgets/mobile_number_field.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isButtonEnabled = _phoneController.text.length == 10;
    });
  }

  Future<void> _onSendOtp() async {
    if (!_isButtonEnabled || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      final phone = _phoneController.text;
      await ActivApiClient.instance.requestOtp('+91$phone');
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.otp, arguments: phone);
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Section (Logo and Banner)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo Center Top
                  const Center(
                    child: AppLogo(width: 72, height: 55, isWhite: false),
                  ),
                  const SizedBox(height: 12),

                  // Background Banner Image with Gradient
                  Stack(
                    children: [
                      Image.asset(
                        AppAssets.loginBanner,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content / Form Area
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // Mobile Number Text Field Widget
                    MobileNumberField(
                      controller: _phoneController,
                      onChanged: (_) => _validateInput(),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    AppButton(
                      title: 'Verify',
                      backgroundColor: AppColors.primary,
                      textColor: Colors.black,
                      borderRadius: 48,
                      showArrow: true,
                      onTap: _isButtonEnabled && !_isSubmitting
                          ? _onSendOtp
                          : null,
                      isDisabled: !_isButtonEnabled,
                      isLoading: _isSubmitting,
                    ),
                    const SizedBox(height: 24),
                    // Spacer to push Terms text to bottom
                    const Spacer(),

                    // Terms & Privacy Agreement RichText
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey99,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.medium,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our\n',
                            ),
                            TextSpan(
                              text: AppStrings.termsAndConditions,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.medium,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.termsConditions);
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: AppStrings.privacyPolicy,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.medium,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.privacyPolicy);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
