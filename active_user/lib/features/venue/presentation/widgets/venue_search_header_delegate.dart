import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_fonts.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/widgets/image/app_svg_network.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class VenueSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final Widget searchBar;
  final Widget sportFilterList;
  final String selectedSportName;
  final String? selectedSportIcon;
  final String? selectedSportIconUrl;
  final VoidCallback onSearchTap;
  final double statusBarHeight;

  VenueSearchHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.searchBar,
    required this.sportFilterList,
    required this.selectedSportName,
    this.selectedSportIcon,
    this.selectedSportIconUrl,
    required this.onSearchTap,
    required this.statusBarHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Calculate the percentage of how much the header is collapsed (0.0 to 1.0)
    final double collapsePercent =
        (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

    final Color? backgroundColor = Color.lerp(
      AppColors.surface,
      AppColors.background,
      collapsePercent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        color: backgroundColor,
        padding: EdgeInsets.only(top: statusBarHeight),
        child: Stack(
          children: [
            // Expanded Content (Fades out as we scroll down)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: expandedHeight,
              child: Opacity(
                opacity: 1.0 - collapsePercent,
                child: IgnorePointer(
                  ignoring: collapsePercent > 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: searchBar,
                        ),
                        const SizedBox(height: 24),
                        sportFilterList,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Collapsed Content (Fades in as we scroll down)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: collapsedHeight,
              child: Opacity(
                opacity: collapsePercent,
                child: IgnorePointer(
                  ignoring: collapsePercent < 0.5,
                  child: Container(
                    height: collapsedHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                    child: GestureDetector(
                      onTap: onSearchTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                if (selectedSportIconUrl != null || selectedSportIcon != null) ...[
                                    if (selectedSportIconUrl!.isNotEmpty)
                                      AppSvgNetwork(
                                        selectedSportIconUrl!,
                                        width: 32,
                                        height: 32,
                                        fallbackAsset: selectedSportIcon ?? 'assets/images/turf.jpg',
                                      )
                                    else if ((selectedSportIcon ?? '').endsWith('.svg'))
                                      AppSvg(selectedSportIcon!, width: 32, height: 32)
                                    else if (selectedSportIcon != null)
                                      Image.asset(
                                        selectedSportIcon!,
                                        width: 32, // Increased from 28
                                        height: 32, // Increased from 28
                                      ),
                                    const SizedBox(width: 12),
                                  ],
                                Text(
                                  selectedSportName,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 20,
                                    fontFamily: AppFonts.bold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            AppSvg(
                              AppAssets.search,
                              color: Colors.white,
                              height: 24,
                              width: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight + statusBarHeight;

  @override
  double get minExtent => collapsedHeight + statusBarHeight;

  @override
  bool shouldRebuild(covariant VenueSearchHeaderDelegate oldDelegate) {
    return oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.selectedSportName != selectedSportName ||
        oldDelegate.selectedSportIcon != selectedSportIcon;
  }
}
