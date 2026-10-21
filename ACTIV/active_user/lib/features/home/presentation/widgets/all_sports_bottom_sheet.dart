import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:activ_user_app/features/home/presentation/widgets/sport_category_card.dart';
import 'package:activ_user_app/routes/app_routes.dart';

import 'package:activ_user_app/shared/widgets/app_bottom_sheet_header.dart';

void showAllSportsBottomSheet(
  BuildContext context,
  List<Map<String, String>> categories,
  Map<String, dynamic> Function(String? selectedSport)? buildRouteArguments,
) {
  final sourceCategories = categories.isNotEmpty
      ? categories
      : mergeAssetSportCategories(const <Map<String, String>>[]);
  final all = List<Map<String, String>>.of(sourceCategories)
    ..sort(
      (a, b) {
        final aCode = normalizeSportCode(a['sportCode'] ?? a['label']);
        final bCode = normalizeSportCode(b['sportCode'] ?? b['label']);
        final aIsOther = aCode == 'other' || aCode == 'other_activity';
        final bIsOther = bCode == 'other' || bCode == 'other_activity';
        if (aIsOther != bIsOther) return aIsOther ? 1 : -1;
        return (a['label'] ?? '').toLowerCase().compareTo(
          (b['label'] ?? '').toLowerCase(),
        );
      },
    );
  final fallbackIcon = iconForSport(null);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const AppBottomSheetHeader(title: 'Pick a Sport'),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: all.length,
                      itemBuilder: (context, index) {
                        final category = all[index];

                        return SportCategoryCard(
                          label: category['label'] ?? '',
                          iconPath:
                              (category['iconPath'] ?? '').isNotEmpty
                              ? category['iconPath']!
                              : fallbackIcon,
                          iconUrl: '',
                          width: null,
                          height: null,
                          margin: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.venueSearch,
                              arguments:
                                  buildRouteArguments?.call(
                                    category['label'],
                                  ) ??
                                  {'selectedSport': category['label']},
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
