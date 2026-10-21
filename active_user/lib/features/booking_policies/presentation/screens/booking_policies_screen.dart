import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_expandable_section.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_rules_section.dart';

class _PolicySection {
  final String title;
  final String icon;
  final List<String> rules;

  const _PolicySection({
    required this.title,
    required this.icon,
    required this.rules,
  });
}

class BookingPoliciesScreen extends StatefulWidget {
  const BookingPoliciesScreen({super.key});

  @override
  State<BookingPoliciesScreen> createState() => _BookingPoliciesScreenState();
}

class _BookingPoliciesScreenState extends State<BookingPoliciesScreen> {
  List<_PolicySection>? _sections;
  String? _error;

  static const _policyTypes = <String, String>{
    'cancellation-policy': 'Cancelation Policy',
    'booking-policy': 'Reschedule Policy',
    'refund-policy': 'Refund Policy',
  };

  static const _noShowRules = <String>[
    'Failure to arrive for a booked slot will be marked as a no-show.',
    'No-shows are strictly non-refundable.',
    'Repeated no-shows may lead to temporary account suspension.',
  ];

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _error = null;
      _sections = null;
    });
    try {
      final sections = <_PolicySection>[];
      for (final entry in _policyTypes.entries) {
        final policy = await ActivApiClient.instance.getPolicy(entry.key);
        final title = policy['title']?.toString() ?? entry.value;
        final body = policy['body']?.toString() ?? '';
        final rules = body
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((sentence) => sentence.trim())
            .where((sentence) => sentence.isNotEmpty)
            .toList();
        sections.add(
          _PolicySection(
            title: title,
            icon: _iconFor(entry.key),
            rules: rules.isEmpty ? const ['Policy is not available right now.'] : rules,
          ),
        );
      }
      sections.add(const _PolicySection(
        title: 'No-show Policy',
        icon: AppAssets.venueRules,
        rules: _noShowRules,
      ));
      if (!mounted) return;
      setState(() => _sections = sections);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load booking policies. Please try again.');
    } finally {
      if (mounted) {
        // Ensure loading state is resolved even on success path.
        setState(() {});
      }
    }
  }

  String _iconFor(String type) {
    switch (type) {
      case 'cancellation-policy':
        return AppAssets.venueRules;
      case 'refund-policy':
        return AppAssets.refundIcon;
      default:
        return AppAssets.reschedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Booking Policies'),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.medium(
                        _error!,
                        color: AppColors.errorRed2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppButton(title: 'Retry', showArrow: false, onTap: _loadPolicies),
                    ],
                  ),
                ),
              )
            : _sections == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        for (var i = 0; i < _sections!.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _buildPolicyCard(_sections![i]),
                        ],
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard(_PolicySection section) {
    return AppCard(
      color: AppColors.blackColor2,
      padding: const EdgeInsets.all(24),
      child: VenueExpandableSection(
        title: section.title,
        iconAsset: section.icon,
        iconColor: AppColors.primary,
        child: VenueRulesSection(rules: section.rules),
      ),
    );
  }
}