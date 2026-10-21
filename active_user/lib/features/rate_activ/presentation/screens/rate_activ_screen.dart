import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/shared/widgets/app_gradient_container.dart';
import 'package:activ_user_app/features/rate_activ/presentation/widgets/review_success_bottom_sheet.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class RateActivScreen extends StatefulWidget {
  const RateActivScreen({super.key});

  @override
  State<RateActivScreen> createState() => _RateActivScreenState();
}

class _RateActivScreenState extends State<RateActivScreen> {
  String _selectedRating = 'Good';
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  bool _isInit = true;
  bool _isEdit = false;
  String? _reviewId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      _isEdit = args['isEdit'] ?? false;
      _reviewId = args['reviewId']?.toString();
      if (_isEdit) {
        final initialRating = args['initialRating'] as int? ?? 5;
        _selectedRating = initialRating >= 5 ? 'Amazing' : (initialRating == 4 ? 'Good' : 'Okay');
        _feedbackController.text = args['initialFeedback']?.toString() ?? '';
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  int get _ratingValue => switch (_selectedRating) {
        'Amazing' => 5,
        'Okay' => 3,
        _ => 4,
      };

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      final bool isVenueReview = args['isVenueReview'] ?? false;
      final String bookingId = args['bookingId']?.toString() ?? '';
      final body = _feedbackController.text.trim();
      if (_isEdit) {
        if (_reviewId == null || _reviewId!.isEmpty) {
          throw const ActivApiException('Review ID is missing.', 0);
        }
        await ActivApiClient.instance
            .editReview(_reviewId!, rating: _ratingValue, body: body);
      } else if (isVenueReview) {
        if (bookingId.isEmpty) {
          throw const ActivApiException('Booking ID is missing.', 0);
        }
        await ActivApiClient.instance
            .submitReview(bookingId, rating: _ratingValue, body: body);
      } else {
        await ActivApiClient.instance.createSupportTicket(
          subject: 'Rate ACTIV Feedback ($_selectedRating)',
          message: body.isEmpty
              ? 'App rated as $_selectedRating.'
              : body,
        );
      }
      if (!mounted) return;
      showReviewSuccessBottomSheet(
        context: context,
        title: 'Review Submitted!',
        description: 'Thanks for sharing your experience.\nYour feedback helps us improve.',
        onDone: () {
          Navigator.of(context).pop(); // pop the bottom sheet
          Navigator.of(context).pop(); // pop the screen
        },
      );
    } on ActivApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final bool isVenueReview = args['isVenueReview'] ?? false;
    final String venueName = args['venueName'] ?? '';
    final String bookingTime = args['bookingTime'] ?? '';

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppHeader(title: _isEdit ? 'Edit Review' : (isVenueReview ? 'Rate & Review' : 'Rate ACTIV')),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                color: AppColors.blackColor2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bold(
                      isVenueReview
                          ? 'How was your experience?'
                          : "How's Your ACTIV Experience So Far?",
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    if (isVenueReview) ...[
                      const SizedBox(height: 8),
                      AppText.small(
                        venueName,
                        color: AppColors.grey99,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 2),
                      AppText.small(
                        bookingTime,
                        color: AppColors.grey99,
                        fontSize: 14,
                      ),
                      const AppDivider(verticalPadding: 24),
                      AppText.bold(
                        'Rate the venue',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRatingOption('Okay', AppAssets.okay),
                        _buildRatingOption('Good', AppAssets.good),
                        _buildRatingOption('Amazing', AppAssets.amazing),
                      ],
                    ),
                    const AppDivider(verticalPadding: 24),
                    AppText.bold(
                      "Tell Us More",
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightGreyBorder,
                          width: 1,
                        ),
                      ),
                      child: AppInpuField(
                        controller: _feedbackController,
                        hintText: 'Please mention here...',
                        maxLines: 5,
                        borderRadius: 12,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AppButton(
                title: _isEdit ? 'Submit' : (isVenueReview ? 'Submit Review' : 'Send Feedback'),
                backgroundColor: AppColors.blackColor2,
                textColor: AppColors.primary,
                isLoading: _isSubmitting,
                showArrow: true,
                onTap: _submit,
              ),
              if (!_isEdit && !isVenueReview) ...[
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.reviewHistory);
                    },
                    child: AppText.medium(
                      'View My Reviews',
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildRatingOption(String text, String iconPath) {
    final isSelected = _selectedRating == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = text;
        });
      },
      child: AppGradientContainer(
        isSelected: isSelected,
        borderRadius: 8,
        backgroundColor: AppColors.blackColor2,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
        child: Column(
          children: [
            AppSvg(iconPath, width: 42, height: 42),
            const SizedBox(height: 8),
            AppText.small(
              text,
              color: isSelected
                  ? AppColors.yellowColorLight
                  : AppColors.textPrimary,
              fontSize: 12,
            ),
          ],
        ),
      ),
    );
  }
}
