import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/features/edit_profile/presentation/widgets/delete_account_bottom_sheet.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final TextEditingController _mobileController = TextEditingController();
  late final TextEditingController _emailController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final String fullName = SharedPrefService.userName ?? '';
    final List<String> nameParts = fullName.split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: SharedPrefService.userEmail ?? '');
    ActivApiClient.instance.getProfile().then((profile) {
      if (!mounted) return;
      final name = profile['name']?.toString() ?? '';
      final parts = name.trim().split(RegExp(r'\s+'));
      _firstNameController.text = parts.isEmpty ? '' : parts.first;
      _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final email = profile['email']?.toString();
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
        SharedPrefService.setUserEmail(email);
      }
      final photo = profile['profilePhoto']?.toString();
      if (photo != null && photo.isNotEmpty) {
        SharedPrefService.setProfilePhotoBase64(photo);
      }
      _mobileController.text = profile['phoneE164']?.toString() ?? '';
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Edit Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo
              Center(
                child: ProfileAvatarPicker(
                  size: 96,
                  onImageChanged: (file) {
                    // TODO: Handle new profile photo
                  },
                ),
              ),
              const AppDivider(verticalPadding: 40),

              // Form Fields
              AppInpuField(
                controller: _firstNameController,
                labelText: 'First name*',
                hintText: 'Enter your first name',
              ),
              const SizedBox(height: 16),
              AppInpuField(
                controller: _lastNameController,
                labelText: 'Last name',
                hintText: 'Enter your last name',
              ),
              const SizedBox(height: 16),
              AppInpuField(
                controller: _mobileController,
                labelText: 'Mobile Number*',
                hintText: 'Enter mobile number',
                enabled: false,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              AppInpuField(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email',
              ),
              const SizedBox(height: 40),

              // Update Profile Button
              AppButton(
                title: 'Update Profile',
                backgroundColor: AppColors.blackColor2,
                textColor: AppColors.primary,
                showArrow: true,
                onTap: _isSaving ? null : () async {
                  final fullName =
                      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                          .trim();
                  if (fullName.isEmpty) {
                    setState(() => _error = 'Please enter your first name.');
                    return;
                  }
                  setState(() { _isSaving = true; _error = null; });
                  final email = _emailController.text.trim();
                  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (email.isNotEmpty && !emailPattern.hasMatch(email)) {
                    setState(() { _error = 'Please enter a valid email address.'; _isSaving = false; });
                    return;
                  }
                  try {
                    await ActivApiClient.instance.updateProfile(
                      name: fullName,
                      email: email.isEmpty ? null : email,
                      profilePhotoBase64: SharedPrefService.profilePhotoBase64 ?? '',
                    );
                    await SharedPrefService.setUserName(fullName);
                    if (email.isNotEmpty) {
                      await SharedPrefService.setUserEmail(email);
                    }
                  } on ActivApiException catch (error) {
                    if (mounted) setState(() { _error = error.message; _isSaving = false; });
                    return;
                  }
                  
                  if (!context.mounted) return;
                   Navigator.of(context).pop();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppText.small(_error!, color: AppColors.errorRed, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 40),

              // Delete Account
              GestureDetector(
                onTap: () {
                  showDeleteAccountBottomSheet(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const AppText(
                      'Delete Account',
                      color: AppColors.white,
                      fontSize: 14,
                    ),
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
}
