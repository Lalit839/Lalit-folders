import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class PolicyDocumentScreen extends StatefulWidget {
  final String policyType;
  final String appBarTitle;

  const PolicyDocumentScreen({
    super.key,
    required this.policyType,
    required this.appBarTitle,
  });

  @override
  State<PolicyDocumentScreen> createState() => _PolicyDocumentScreenState();
}

class _PolicyDocumentScreenState extends State<PolicyDocumentScreen> {
  String? _body;
  String? _title;
  String? _version;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final policy = await ActivApiClient.instance.getPolicy(widget.policyType);
      if (!mounted) return;
      setState(() {
        _title = policy['title']?.toString();
        _body = policy['body']?.toString();
        _version = policy['version']?.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load ${widget.appBarTitle.toLowerCase()}. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppHeader(title: widget.appBarTitle),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
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
                          AppButton(title: 'Retry', showArrow: false, onTap: _loadPolicy),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_title != null && _title!.isNotEmpty) ...[
                          AppText.bold(
                            _title!,
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                          if (_version != null) ...[
                            const SizedBox(height: 4),
                            AppText.small(
                              'Version $_version',
                              fontSize: 12,
                              color: AppColors.grey99,
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        AppText.medium(
                          _body ?? '',
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}