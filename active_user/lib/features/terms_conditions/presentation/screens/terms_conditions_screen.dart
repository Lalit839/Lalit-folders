import 'package:flutter/material.dart';
import 'package:activ_user_app/features/privacy_policy/presentation/screens/policy_document_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyDocumentScreen(
      policyType: 'terms-of-service',
      appBarTitle: 'Terms & Conditions',
    );
  }
}