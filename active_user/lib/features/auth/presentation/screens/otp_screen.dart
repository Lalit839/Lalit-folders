import 'dart:async';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/widgets/fields/app_otp_field.dart';
import 'package:activ_user_app/core/constants/app_fonts.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/services/push_service.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;

  const OTPScreen({super.key, required this.mobileNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _hasError = false;
  Timer? _resendTimer;
  int _timerSeconds = 59;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);

    // Simulate OTP SMS auto-fill after 2 seconds
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (mounted && _otpController.text.isEmpty) {
    //     _otpController.text = _expectedOtp;
    //   }
    // });

    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_timerSeconds > 0) {
          setState(() {
            _timerSeconds--;
          });
        } else {
          setState(() {
            _canResend = true;
          });
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
    setState(() {
      _isButtonEnabled = _otpController.text.length == 4;
    });
  }

  Future<void> _onVerify() async {
    if (!_isButtonEnabled || _isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final phone = '+91${widget.mobileNumber}';
    final code = _otpController.text;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await ActivApiClient.instance.verifyOtp(phone, code);
      await PushService.instance.sync();
    } on ActivApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_otpErrorMessage(error))));
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    var profileName = '';
    try {
      final profile = await ActivApiClient.instance.getProfile();
      profileName = profile['name']?.toString().trim() ?? '';
    } on ActivApiException {
      profileName = '';
    }
    final cachedName = SharedPrefService.userName?.trim() ?? '';
    final hasName = profileName.isNotEmpty;
    if (hasName && profileName != cachedName) {
      await SharedPrefService.setUserName(profileName);
    }
    if (hasName) {
      await SharedPrefService.setLoggedIn(true);
    }

    if (!mounted) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('OTP Verified Successfully!')),
      );
    navigator.pushNamedAndRemoveUntil(
      hasName ? AppRoutes.dashboard : AppRoutes.userName,
      (route) => false,
    );
  }

  Future<void> _onResendOtp() async {
    if (!_canResend) return;

    final messenger = ScaffoldMessenger.of(context);
    final phone = '+91${widget.mobileNumber}';
    setState(() {
      _canResend = false;
    });

    try {
      await ActivApiClient.instance.requestOtp(phone);
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('OTP Resent Successfully!')),
        );
      _startTimer();
    } on ActivApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _canResend = true;
      });
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_otpErrorMessage(error))));
    }
  }

  String _otpErrorMessage(ActivApiException error) {
    if (error.statusCode == 401) {
      return 'Invalid or expired OTP. Please check the code or request a new one.';
    }
    if (error.statusCode == 429) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    if (error.statusCode == 0 || error.statusCode == 503) {
      return 'OTP service is temporarily unavailable. Please try again shortly.';
    }
    return error.message;
  }

  String _getMaskedNumber() {
    if (widget.mobileNumber.length >= 10) {
      final firstPart = widget.mobileNumber.substring(0, 5);
      final secondPart = widget.mobileNumber.substring(5, 10);
      return '+91 $firstPart-$secondPart';
    }
    return '+91 ${widget.mobileNumber}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: 'Verification'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),

                        // Logo Center Top
                        const Center(
                          child: AppLogo(width: 72, height: 55, isWhite: false),
                        ),
                        const SizedBox(height: 32),

                        // Heading
                        Center(
                          child: AppText.bold(
                            'Enter Verification Code',
                            color: AppColors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subheading with masked phone number
                        Center(
                          child: AppText(
                            'Enter the verification code we\'ve sent to your\n${_getMaskedNumber()}',
                            color: AppColors.grey99,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Reusable OTP Input Field
                        Center(
                          child: AppOtpField(
                            controller: _otpController,
                            focusNode: _focusNode,
                             length: 4,
                            hasError: _hasError,
                            onCompleted: (val) => _onVerify(),
                          ),
                        ),
                        const SizedBox(height: 24),



                        // Verify Action Button
                        AppButton(
                          title: 'Confirm',
                          showArrow: true,
                          onTap: _isButtonEnabled ? _onVerify : null,
                          isDisabled: !_isButtonEnabled,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: AppText(
                            'Your verification code is valid for 5 minutes.',
                            color: AppColors.grey99,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: _canResend ? _onResendOtp : null,
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey99,
                                  fontFamily: AppFonts.regular,
                                ),
                                children: [
                                  TextSpan(
                                    text: _canResend
                                        ? 'Didn\'t receive it? '
                                        : 'Resend ',
                                  ),
                                  TextSpan(
                                    text: _canResend
                                        ? 'Resend OTP'
                                        : '00:${_timerSeconds.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: _canResend
                                          ? AppColors.primary
                                          : AppColors.white,
                                      fontFamily: _canResend ? AppFonts.medium : AppFonts.regular,
                                      fontWeight: _canResend ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Bottom info row
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
