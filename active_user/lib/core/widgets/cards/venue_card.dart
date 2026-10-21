import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/features/saved_venues/presentation/state/saved_venues_provider.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/widgets/image/app_network_image.dart';
import 'package:activ_user_app/core/widgets/cards/offer_badge.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/shared/widgets/venue_rating_badge.dart';
import 'package:activ_user_app/core/widgets/buttons/animated_bookmark_button.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class VenueCard extends ConsumerStatefulWidget {
  final String title;
  final String imagePath;
  final List<String>? imageUrls;
  final String distance;
  final String location;
  final String discount;
  final double rating;
  final int reviews;
  final String? id;
  final bool isAvailable;
  final Function(bool)? onBookmarkToggle;
  final VoidCallback? onTap;

  const VenueCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.imageUrls,
    required this.distance,
    required this.location,
    required this.discount,
    this.rating = 0.0,
    this.reviews = 0,
    this.id,
    this.isAvailable = true,
    this.onBookmarkToggle,
    this.onTap,
  });

  @override
  ConsumerState<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends ConsumerState<VenueCard> {
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.imageUrls != null && widget.imageUrls!.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 4), (
        Timer timer,
      ) {
        if (_pageController.hasClients) {
          int nextPage = _currentImageIndex + 1;
          if (nextPage >= widget.imageUrls!.length) {
            nextPage = 0;
            _pageController.jumpToPage(nextPage);
          } else {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Custom Google Rating Badge in bottom right corner
  Widget _buildRatingBadge() {
    return VenueRatingBadge(rating: widget.rating, reviews: widget.reviews);
  }

  // Custom slanted top-left offer ribbon tag
  Widget _buildTopLeftTag() {
    if (!widget.isAvailable) {
      return Positioned(
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
      );
    }
    if (widget.discount.isEmpty) return const SizedBox.shrink();
    return OfferBadge(discount: widget.discount);
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.blackColor2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGreyBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 1. Background Image Carousel
            Positioned.fill(
              child: (widget.imageUrls != null && widget.imageUrls!.isNotEmpty)
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: widget.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return AppNetworkImage(
                          imagePath: widget.imageUrls![index],
                          borderRadius: 0,
                        );
                      },
                    )
                  : AppNetworkImage(
                      imagePath: widget.imagePath,
                      borderRadius: 0,
                    ),
            ),

            // 2. Dark Gradient Overlay for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: widget.isAvailable
                  ? null
                  : 0, // Fill if unavailable, otherwise bottom-aligned
              height: widget.isAvailable ? 100 : null,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            ),

            // 2.5 Pagination Dots (if carousel)
            if (widget.imageUrls != null && widget.imageUrls!.length > 1)
              Positioned(
                bottom: 21,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls!.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentImageIndex == index ? 6 : 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Removed internal offer tag

            // 4. Bookmark (Save) Button
            Positioned(
              top: 12,
              right: 12,
              child: Consumer(
                builder: (context, ref, child) {
                  final venueId =
                      widget.id ?? widget.title; // fallback to title if no id
                  final isSaved = ref.watch(
                    savedVenuesProvider.select(
                      (venues) => venues.any((v) => v['id'] == venueId),
                    ),
                  );

                  return AnimatedBookmarkButton(
                    initialBookmarked: isSaved,
                    onTap: (currentBookmarked) async {
                      final venueData = {
                        'id': venueId,
                        'title': widget.title,
                        'imagePath': widget.imagePath,
                        'distance': widget.distance,
                        'location': widget.location,
                        'discount': widget.discount,
                        'rating': widget.rating,
                        'reviews': widget.reviews,
                        'isAvailable': widget.isAvailable,
                      };

                      final notifier = ref.read(savedVenuesProvider.notifier);
                      notifier.toggleBookmark(venueData);

                      try {
                        if (currentBookmarked) {
                          await ActivApiClient.instance.removeSavedVenue(
                            venueId,
                          );
                        } else {
                          await ActivApiClient.instance.saveVenue(venueId);
                        }
                      } catch (_) {
                        notifier.toggleBookmark(venueData);
                      }

                      if (widget.onBookmarkToggle != null) {
                        widget.onBookmarkToggle!(!currentBookmarked);
                      }

                      return !currentBookmarked;
                    },
                  );
                },
              ),
            ),

            // 5. Overlaid Title & Details at the bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Title and Distance/Location Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.bold(
                          widget.title,
                          fontSize: 16,
                          color: AppColors.white,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AppText.small(
                          [
                            if (widget.distance.isNotEmpty) widget.distance,
                            if (widget.location.isNotEmpty) widget.location,
                          ].join(' | '),
                          fontSize: 13,
                          color: AppColors.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rating Badge (only when a real rating exists)
                  if (widget.rating > 0) _buildRatingBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.isAvailable) {
      cardContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: cardContent,
      );
    }

    return GestureDetector(
      onTap: widget.isAvailable ? widget.onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          cardContent,
          // 5. The Top Left Tag (Offer or Unavailable) placed outside ColorFiltered
          _buildTopLeftTag(),
        ],
      ),
    );
  }
}
