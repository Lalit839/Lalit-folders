import 'package:activ_user_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class UserNameScreen extends StatefulWidget {
  const UserNameScreen({super.key});

  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _isButtonEnabled = _firstNameController.text.trim().isNotEmpty;
    });
  }

  void _onContinue() async {
    if (_isButtonEnabled) {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      try {
        await ActivApiClient.instance.updateProfile(name: fullName);
        await SharedPrefService.setUserName(fullName);
        await SharedPrefService.setLoggedIn(true);
      } on ActivApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error.statusCode == 401
                    ? 'Session expired. Please verify your phone number again.'
                    : error.message,
              ),
            ),
          );
        return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Unable to save your profile. Please try again.'),
            ),
          );
        return;
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.locationPermission, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                        const SizedBox(height: 16),

                        // Heading
                        Center(
                          child: AppText.bold(
                            'Let\'s personalize your profile',
                            color: AppColors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subheading
                        Center(
                          child: AppText.small(
                            'This helps personalize your ACTIV experience.',
                            color: AppColors.grey99,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // First Name Input Field
                        AppInpuField(
                          controller: _firstNameController,
                          hintText: 'First name',
                          labelText: 'First name*',
                        ),
                        const SizedBox(height: 16),

                        // Last Name Input Field
                        AppInpuField(
                          controller: _lastNameController,
                          hintText: 'Last name',
                          labelText: 'Last name',
                        ),
                        const SizedBox(height: 24),

                        // Continue Button
                        AppButton(
                          title: 'Continue',
                          showArrow: true,
                          onTap: _isButtonEnabled ? _onContinue : null,
                          isDisabled: !_isButtonEnabled,
                        ),

                        const Spacer(),
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
