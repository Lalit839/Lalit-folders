import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/widgets/image/app_network_image.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/core/widgets/buttons/animated_bookmark_button.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/features/saved_venues/presentation/state/saved_venues_provider.dart';

class SwipeVenueCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> venue;
  final VoidCallback? onTap;
  final bool showButton;
  final double width;

  const SwipeVenueCard({
    super.key,
    required this.venue,
    this.onTap,
    this.showButton = true,
    this.width = 321,
  });

  @override
  ConsumerState<SwipeVenueCard> createState() => _SwipeVenueCardState();
}

class _SwipeVenueCardState extends ConsumerState<SwipeVenueCard> {
  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.venue['isAvailable'] ?? true;

    return GestureDetector(
      onTap: isAvailable ? widget.onTap : null,
      child: Container(
        width: widget.width,
        height: 344,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGreyBorder, width: 1),
        ),
        clipBehavior: Clip.none,
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    final bool isAvailable = widget.venue['isAvailable'] ?? true;
    Widget stack = Stack(
      clipBehavior: Clip.none,
          children: [
            // Background Image (Fills the entire card)
            Positioned.fill(
              child: AppNetworkImage(
                imagePath: widget.venue['imagePath'] ?? '',
                borderRadius: 12,
              ),
            ),
            // Dark Gradient Overlay for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: isAvailable ? null : 0, // Fill if unavailable, otherwise bottom-aligned
              height: isAvailable ? 240 : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.transparent, Colors.black],
                    stops: isAvailable ? const [0.0, 0.9796] : const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            // Bookmark Button
            Positioned(
              top: 12,
              right: 12,
              child: Consumer(
                builder: (context, ref, child) {
                  final venueId = widget.venue['id']?.toString() ?? widget.venue['title'];
                  final savedVenues = ref.watch(savedVenuesProvider);
                  final isSaved = savedVenues.any((v) => v['id'] == venueId);
                  
                  return AnimatedBookmarkButton(
                    initialBookmarked: isSaved,
                    onTap: (currentBookmarked) async {
                      final venueData = Map<String, dynamic>.from(widget.venue);
                      venueData['id'] = venueId;

                      final notifier = ref.read(savedVenuesProvider.notifier);
                      notifier.toggleBookmark(venueData);

                      try {
                        if (currentBookmarked) {
                          await ActivApiClient.instance.removeSavedVenue(venueId);
                        } else {
                          await ActivApiClient.instance.saveVenue(venueId);
                        }
                      } catch (_) {
                        notifier.toggleBookmark(venueData);
                      }
                      return !currentBookmarked;
                    },
                  );
                }
              ),
            ),
            // Details overlay (Discount, Title, Address) - Centered
            Positioned(
              left: 16,
              bottom: 40, // Pushed up to make space for the overlapping button
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Discount Badge
                  if (widget.venue['discount'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 23,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AppText.bold(
                            widget.venue['discount'],
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  // Title
                  AppText.bold(
                    widget.venue['title'] ?? '',
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    height: 1.0,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Distance | Address
                  AppText.small(
                    '${widget.venue['distance'] ?? ''} | ${widget.venue['location'] ?? ''}',
                    color: AppColors.textPrimary,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    height: 1.0,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Pay Per Session Button (Overlapping bottom edge & centered) - Only shown for top card
            if (widget.showButton)
              Positioned(
                bottom: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(56),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(
                      top: 2,
                      right: 12,
                      bottom: 2,
                      left: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.blackColor1,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppText.small('₹', fontSize: 16),
                        ),
                        const SizedBox(width: 8),

                        AppText.bold(
                          'Pay Per Session',
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
    );

    if (!isAvailable) {
      stack = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: stack,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        stack,
        if (!isAvailable)
          Positioned(
            top: 15,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD50D0D),
                borderRadius: BorderRadius.circular(40),
              ),
              child: AppText.bold(
                'Currently Unavailable',
                color: const Color(0xFFF6F6F6),
                fontSize: 12,
                height: 1.0,
              ),
            ),
          ),
      ],
    );
  }
}
