import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/profile/presentation/widgets/profile_menu_item.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Legal'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileMenuItem(
                title: 'Privacy Policy',
                iconPath: AppAssets.privacySecurity,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
                },
              ),
              const AppDivider(verticalPadding: 0),
              ProfileMenuItem(
                title: 'Terms & Conditions',
                iconPath: AppAssets.tnc,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.termsConditions);
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
