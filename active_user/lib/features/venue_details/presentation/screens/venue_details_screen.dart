import 'dart:async';

import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/venue_details/data/models/venue_details_model.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_image_carousel.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_basic_info.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_activity_list.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_offer_list.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_amenities_section.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_rules_section.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/venue_expandable_section.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/core/widgets/buttons/animated_bookmark_button.dart';
import 'package:activ_user_app/features/venue_details/presentation/widgets/share/venue_share_bottom_sheet.dart';
import 'package:activ_user_app/core/services/share_service.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class VenueDetailsScreen extends StatefulWidget {
  final String? venueId;
  const VenueDetailsScreen({super.key, this.venueId});

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  bool _isSaved = false;
  String? _selectedActivityId;
  VenueDetailsModel? _venueDetails;
  bool _isLoading = true;
  String? _error;
  int _availableSlots = 0;

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    if (widget.venueId == null || widget.venueId!.isEmpty) {
      setState(() {
        _error = 'Venue was not specified.';
        _isLoading = false;
      });
      return;
    }
    final venueId = widget.venueId!;
    try {
      final result = await ActivApiClient.instance.getVenue(venueId);
      if (!mounted) return;
      final venue = VenueDetailsModel.fromJson(result);
      setState(() {
        _venueDetails = venue;
        _selectedActivityId = venue.activities.isEmpty
            ? null
            : venue.activities.first.id;
        _isLoading = false;
      });
      unawaited(_loadAvailability(venueId));
      unawaited(_loadSavedState(venue.id));
    } on ActivApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load this venue.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAvailability(String venueId) async {
    try {
      final availability = await ActivApiClient.instance.getAvailability(
        venueId,
        date: DateTime.now().toIso8601String().substring(0, 10),
      );
      if (!mounted) return;
      setState(() {
        _availableSlots = availability['items'] is List
            ? (availability['items'] as List).length
            : 0;
      });
    } catch (_) {
      // Slot availability is secondary; keep the venue page usable.
    }
  }

  Future<void> _loadSavedState(String venueId) async {
    try {
      final saved = await ActivApiClient.instance.getSavedVenues();
      if (!mounted) return;
      setState(() {
        _isSaved = saved.any(
          (item) =>
              item is Map<String, dynamic> &&
              (item['venue'] as Map<String, dynamic>?)?['id'] == venueId,
        );
      });
    } catch (_) {
      // Saved state can be retried when the user taps the bookmark.
    }
  }

  Future<void> _openInMaps() async {
    final venue = _venueDetails;
    if (venue == null) return;
    final query = Uri.encodeComponent('${venue.name} ${venue.address}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullScreenGallery() {
    final venue = _venueDetails;
    if (venue == null || venue.imageUrls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(images: venue.imageUrls),
      ),
    );
  }

  Future<void> _toggleVenueSave() async {
    final venue = _venueDetails;
    if (venue == null) return;
    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
    });
    try {
      if (wasSaved) {
        await ActivApiClient.instance.removeSavedVenue(venue.id);
      } else {
        await ActivApiClient.instance.saveVenue(venue.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaved = wasSaved;
      });
    }
  }

  void _onShareTap() {
    final venue = _venueDetails!;
    VenueShareBottomSheet.show(
      context,
      imageUrl: venue.imageUrls.isNotEmpty ? venue.imageUrls.first : '',
      name: venue.name,
      sports: venue.activities.isNotEmpty
          ? venue.activities.map((a) => a.name).join(', ')
          : 'Sports',
      location: venue.address,
      rating: venue.rating,
      reviewCount: venue.reviewCount,
      isSaved: _isSaved,
      onSaveToggle: () {
        unawaited(_toggleVenueSave());
        Navigator.pop(
          context,
        ); // Optional: close bottom sheet after saving, or leave it open
      },
      shareUrl: 'https://activ.app/venues/${venue.id}',
      shareContent: ShareService().buildVenueShareMessage(
        name: venue.name,
        sports: venue.activities.isNotEmpty
            ? venue.activities.map((a) => a.name).join(', ')
            : 'Football', // Default as per prompt if needed
        venueUrl: 'https://activ.app/venues/${venue.id}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _venueDetails == null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Venue Details'),
        body: Center(child: Text('Unable to load this venue.')),
      );
    }
    final venue = _venueDetails!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Venue Details',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBookmarkButton(
              initialBookmarked: _isSaved,
              backgroundColor: AppColors.blackColor2,
              onTap: (isBookmarked) async {
                await _toggleVenueSave();
                return !isBookmarked;
              },
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _onShareTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.blackColor2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvg(
                    AppAssets.share,
                    color: AppColors.textPrimary,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                VenueImageCarousel(
                  imageUrls: venue.imageUrls,
                  onImageTap: () {
                    _openFullScreenGallery();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VenueBasicInfo(
                        name: venue.name,
                        address: venue.address,
                        distance: venue.distance,
                        rating: venue.rating,
                        reviewCount: venue.reviewCount,
                        onGetDirectionsTap: () {
                          _openInMaps();
                        },
                      ),
                      const SizedBox(height: 12),
                      AppText.small(
                        _availableSlots == 0
                            ? 'No slots available today'
                            : '$_availableSlots slots available today',
                        color: _availableSlots == 0
                            ? AppColors.grey99
                            : AppColors.primary,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 40),
                      Divider(color: AppColors.lightGreyBorder, height: 1),
                      const SizedBox(height: 40),
                      VenueActivityList(
                        activities: venue.activities,
                        selectedActivityId: _selectedActivityId,
                        onActivitySelected: (id) {
                          setState(() {
                            _selectedActivityId = id;
                          });
                        },
                      ),
                      const SizedBox(height: 40),
                      Divider(color: AppColors.lightGreyBorder, height: 1),
                      const SizedBox(height: 40),
                      VenueOfferList(offers: venue.offers),
                      const SizedBox(height: 40),
                      Divider(color: AppColors.lightGreyBorder, height: 1),
                      const SizedBox(height: 40),
                      VenueAmenitiesSection(amenities: venue.amenities),
                      const SizedBox(height: 40),
                      Divider(color: AppColors.lightGreyBorder, height: 1),
                      const SizedBox(height: 40),
                      VenueExpandableSection(
                        title: 'Venue Rules',
                        iconAsset: AppAssets.venueRules,
                        child: VenueRulesSection(rules: venue.rules),
                      ),
                      const SizedBox(height: 24),

                      VenueExpandableSection(
                        title: 'Cancellation Policy',
                        iconAsset: AppAssets.venueRules,
                        child: AppText.small(
                          venue.cancellationPolicy,
                          color: AppColors.greyBorder,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      VenueExpandableSection(
                        title: 'FAQs',
                        iconAsset: AppAssets.faqs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: venue.faqs.map((faq) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.medium(
                                    faq.question,
                                    color: AppColors.textPrimary,
                                  ),
                                  const SizedBox(height: 4),
                                  AppText(
                                    faq.answer,
                                    color: AppColors.greyBorder,
                                    fontSize: 16,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomActionBar.fullWidthAction(
        title: 'Book Your Slot',
        onTap: venue.activities.isEmpty
            ? null
            : () {
                final activityName = venue.activities
                    .firstWhere(
                      (a) => a.id == _selectedActivityId,
                      orElse: () => venue.activities.first,
                    )
                    .name;
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookSlot,
                  arguments: {'activity': activityName, 'venueId': venue.id},
                );
              },
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  const _FullScreenGallery({required this.images});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
