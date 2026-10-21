import 'package:flutter/material.dart';
import 'package:activ_user_app/features/privacy_policy/presentation/screens/policy_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyDocumentScreen(
      policyType: 'privacy-policy',
      appBarTitle: 'Privacy Policy',
    );
  }
}