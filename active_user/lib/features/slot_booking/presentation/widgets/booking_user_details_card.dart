import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';
import 'package:activ_user_app/shared/widgets/app_card.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/slot_booking/presentation/widgets/edit_details_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';

class BookingUserDetailsCard extends StatefulWidget {
  const BookingUserDetailsCard({super.key});

  @override
  State<BookingUserDetailsCard> createState() => _BookingUserDetailsCardState();
}

class _BookingUserDetailsCardState extends State<BookingUserDetailsCard> {
  String _userName = 'Loading...';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ActivApiClient.instance.getProfile();
      if (mounted) {
        setState(() {
          _userName = profile['name'] ?? 'ACTIV User';
          _userPhone = profile['phoneE164'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = SharedPrefService.userName ?? 'ACTIV User';
        });
      }
    }
  }

  Future<void> _editDetails() async {
    final result = await EditDetailsBottomSheet.show(
      context,
      firstName: _userName.split(' ').first,
      lastName: _userName.split(' ').length > 1
          ? _userName.split(' ').sublist(1).join(' ')
          : '',
      phone: _userPhone,
    );
    if (result == null || !mounted) return;
    final fullName =
        '${result.firstName} ${result.lastName}'.trim();
    try {
      await ActivApiClient.instance.updateProfile(name: fullName);
    } on ActivApiException {
      // Non-fatal: still reflect locally even if the backend call fails.
    }
    if (mounted) {
      setState(() {
        _userName = fullName.isEmpty ? _userName : fullName;
        _userPhone = result.phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubSectionHeader(title: 'Your Details'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                    ), // Pushes the icon down slightly to match text
                    child: AppSvg(AppAssets.userIcon),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.medium(
                          _userName,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                        const SizedBox(height: 2),
                        if (_userPhone.isNotEmpty)
                          AppText.medium(
                            _userPhone,
                            color: AppColors.greyBorder,
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _editDetails,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.medium('Edit', color: AppColors.greyBorder),
                        const SizedBox(width: 4),
                        const AppSvg(
                          AppAssets.forwardArrow,
                          color: AppColors.greyBorder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppDivider(verticalPadding: 12),
              AppText(
                'Information mentioned above will be used for generating the invoice and sending out the tickets.',
                color: AppColors.greyBorder,
                height: 1.4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

