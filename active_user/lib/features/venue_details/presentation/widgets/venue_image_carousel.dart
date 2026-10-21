import 'package:flutter/material.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_image_item.dart';

class VenueImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onImageTap;

  const VenueImageCarousel({
    super.key,
    required this.imageUrls,
    required this.onImageTap,
  });

  @override
  State<VenueImageCarousel> createState() => _VenueImageCarouselState();
}

class _VenueImageCarouselState extends State<VenueImageCarousel> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.9 allows the next/prev images to be slightly visible
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox(height: 280);
    }

    return SizedBox(
      height: 366,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return VenueImageItem(
                imageUrl: widget.imageUrls[index],
                onTap: widget.onImageTap,
              );
            },
          ),
          // Positioned(
          //   bottom: 16,
          //   right: 32, // Offset inward because of viewportFraction padding
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.6),
          //       borderRadius: BorderRadius.circular(16),
          //     ),
          //     child: AppText.medium(
          //       '${_currentIndex + 1} / ${widget.imageUrls.length}',
          //       color: AppColors.white,
          //       fontSize: 12,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
