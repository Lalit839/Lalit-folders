import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/core/widgets/cards/venue_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_user_app/features/saved_venues/presentation/state/saved_venues_provider.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/core/widgets/shimmer/app_shimmer.dart';
import 'package:activ_user_app/core/widgets/shimmer/shimmer_box.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class SavedVenuesScreen extends ConsumerStatefulWidget {
  const SavedVenuesScreen({super.key});

  @override
  ConsumerState<SavedVenuesScreen> createState() => _SavedVenuesScreenState();
}

class _SavedVenuesScreenState extends ConsumerState<SavedVenuesScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    try {
      final response = await ActivApiClient.instance.getSavedVenues();
      final venues = response.whereType<Map<String, dynamic>>().map((item) {
        final venue = item['venue'] as Map<String, dynamic>? ?? item;
        return <String, dynamic>{
          'id': venue['id']?.toString(),
          'title': venue['name']?.toString() ?? '',
          'location': venue['cityCode']?.toString() ?? '',
          'imagePath': ((venue['imageUrls'] as List?) ?? const []).isNotEmpty
              ? (venue['imageUrls'] as List).first.toString()
              : '',
          'distance': venue['distance']?.toString() ?? '',
          'discount': venue['discount']?.toString() ?? '',
          'rating': (venue['rating'] as num?)?.toDouble() ?? 0.0,
          'reviews': (venue['reviewCount'] as num?)?.toInt() ?? 0,
          'isAvailable': true,
        };
      }).toList();
      if (mounted) {
        ref.read(savedVenuesProvider.notifier).setVenues(venues);
        setState(() => _isLoading = false);
      }
    } on ActivApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Saved Venues'),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 32),
        itemBuilder: (context, index) => const AppShimmer(
          child: ShimmerBox(
            width: double.infinity,
            height: 180,
            borderRadius: 8,
          ),
        ),
      );
    }

    final savedVenues = ref.watch(savedVenuesProvider);

    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: AppText(_error!, color: AppColors.errorRed, textAlign: TextAlign.center)));
    }
    if (savedVenues.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: savedVenues.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final venue = savedVenues[index];
        return VenueCard(
          id: venue['id']?.toString(),
          title: venue['title']?.toString() ?? '',
          imagePath: venue['imagePath']?.toString() ?? '',
          distance: venue['distance']?.toString() ?? '',
          location: venue['location']?.toString() ?? '',
          discount: venue['discount']?.toString() ?? '',
          rating: (venue['rating'] as num?)?.toDouble() ?? 0.0,
          reviews: (venue['reviews'] as num?)?.toInt() ?? 0,
          isAvailable: venue['isAvailable'] ?? true,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.venueDetails,
              arguments: {'venueId': venue['id']?.toString()},
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bold(
            'Discover. Play. Repeat.',
            color: AppColors.textPrimary,
            fontSize: 22,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppText.small(
            'Find your favorite sports venues and save them to your ACTIV wishlist.',
            color: AppColors.grey99,
            fontSize: 16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppButton(
            title: 'Create Wishlist',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (route) => false,
              );
            },
            backgroundColor: AppColors.blackColor2,
            textColor: AppColors.primary,
            showArrow: true,
          ),
        ],
      ),
    );
  }
}
