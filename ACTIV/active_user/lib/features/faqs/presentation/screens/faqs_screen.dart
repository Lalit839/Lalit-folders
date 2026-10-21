import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

const List<Map<String, String>> _faqContent = [
  {
    'question': 'How do I book a sports venue?',
    'answer':
        'Browse venues, select your preferred date and time, then confirm your booking through the app.',
  },
  {
    'question': 'Can I cancel my booking?',
    'answer':
        'Yes, you can cancel eligible bookings from My Bookings. Refunds depend on the venue cancellation policy.',
  },
  {
    'question': 'Can I reschedule my booking?',
    'answer':
        'Yes, confirmed bookings can be rescheduled once before the slot starts, subject to availability.',
  },
  {
    'question': 'When will I receive my booking confirmation?',
    'answer':
        'Your booking confirmation appears in the app as soon as payment is completed successfully.',
  },
  {
    'question': 'What payment methods are accepted?',
    'answer':
        'You can pay using UPI, cards, wallets, and other supported online payment methods at checkout.',
  },
];

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  List<Map<String, String>> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
    });
    if (!mounted) return;
    setState(() {
      _faqs = _faqContent;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showGradient: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(title: 'FAQs'),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _faqs.isEmpty
              ? const _FaqEmptyView()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 18.0,
                  ),
                  itemCount: _faqs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return _FaqItem(
                      number: index + 1,
                      question: faq['question'] ?? '',
                      answer: faq['answer'] ?? '',
                      isInitiallyExpanded: index == 0,
                    );
                  },
                ),
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
  final int number;
  final String question;
  final String answer;
  final bool isInitiallyExpanded;

  const _FaqItem({
    required this.number,
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
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      borderRadius: 8,
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
                    '${widget.number}. ${widget.question}',
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    letterSpacing: 0,
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            AppText(
              widget.answer,
              color: AppColors.greyBorder,
              fontSize: 15,
              height: 1.35,
            ),
          ],
        ],
      ),
    );
  }
}
