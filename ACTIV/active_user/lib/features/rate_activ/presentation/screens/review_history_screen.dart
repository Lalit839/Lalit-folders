import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  List<dynamic>? _reviews;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reviews = await ActivApiClient.instance.getReviewHistory();
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load review history. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _getRatingText(int rating) {
    if (rating >= 5) return 'Amazing';
    if (rating == 4) return 'Good';
    return 'Okay';
  }

  String _getRatingIcon(int rating) {
    if (rating >= 5) return AppAssets.amazing;
    if (rating == 4) return AppAssets.good;
    return AppAssets.okay;
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays} days ago';
      if (difference.inHours > 0) return '${difference.inHours} hours ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes} mins ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AppHeader(title: 'Review History'),
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
                            AppButton(title: 'Retry', showArrow: false, onTap: _loadReviews),
                          ],
                        ),
                      ),
                    )
                  : _reviews == null || _reviews!.isEmpty
                      ? Center(
                          child: AppText.medium(
                            'No reviews found.',
                            color: AppColors.grey99,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _reviews!.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final review = _reviews![index];
                            final rating = (review['rating'] as num?)?.toInt() ?? 0;
                            final body = review['body']?.toString() ?? '';
                            final date = review['createdAt']?.toString() ?? '';
                            final reviewId = review['id']?.toString() ?? '';

                            return AppCard(
                              color: AppColors.blackColor2,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSvg(_getRatingIcon(rating), width: 40, height: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AppText.bold(
                                              _getRatingText(rating),
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            AppText.small(
                                              _timeAgo(date),
                                              color: AppColors.grey99,
                                              fontSize: 10,
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () async {
                                                await Navigator.of(context).pushNamed(
                                                  AppRoutes.rateActiv,
                                                  arguments: {
                                                    'isEdit': true,
                                                    'reviewId': reviewId,
                                                    'initialRating': rating,
                                                    'initialFeedback': body,
                                                  },
                                                );
                                                // Reload after edit
                                                _loadReviews();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.lightGreyBorder),
                                                ),
                                                child: const AppSvg(
                                                  AppAssets.profileEdit,
                                                  width: 16,
                                                  height: 16,
                                                  color: AppColors.grey99,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        AppText.small(
                                          body,
                                          color: AppColors.grey99,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
