import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ActivApiClient.instance.getFaqs();
      if (!mounted) return;
      setState(() {
        _faqs = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load FAQs. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(title: 'FAQs'),
        body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _FaqErrorView(message: _error!, onRetry: _loadFaqs)
                : _faqs.isEmpty
                    ? const _FaqEmptyView()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        itemCount: _faqs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final faq = _faqs[index];
                          return _FaqItem(
                            question: faq['question']?.toString() ?? '',
                            answer: faq['answer']?.toString() ?? '',
                            isInitiallyExpanded: index == 0,
                          );
                        },
                      ),
        ),
      ),
    );
  }
}

class _FaqErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FaqErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.medium(
              message,
              color: AppColors.errorRed2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              title: 'Retry',
              showArrow: false,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqEmptyView extends StatelessWidget {
  const _FaqEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText.medium(
        'No FAQs available right now.',
        color: AppColors.grey99,
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isInitiallyExpanded;

  const _FaqItem({
    required this.question,
    required this.answer,
    this.isInitiallyExpanded = false,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.blackColor2,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppText(
                    widget.question,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            AppText.small(
              widget.answer,
              color: AppColors.greyBorder,
              fontSize: 16,
            ),
          ],
        ],
      ),
    );
  }
}