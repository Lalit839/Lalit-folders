import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class VenueSummaryCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String sport;
  final String location;

  const VenueSummaryCard({
    super.key,
    this.imageUrl,
    required this.name,
    required this.sport,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 107,
            height: 82,
            color: AppColors.lightGrey,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? Image.asset('assets/images/turf.jpg', fit: BoxFit.cover)
                : imageUrl!.startsWith('assets/')
                ? Image.asset(imageUrl!, fit: BoxFit.cover)
                : Image.network(imageUrl!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bold(name, color: AppColors.textPrimary),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: _IconText(
                      iconPath: _getSportIconPath(sport),
                      label: sport,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: AppText('|', color: AppColors.grey99, fontSize: 16),
                  ),
                  Expanded(
                    child: _IconText(
                      iconPath: AppAssets.location,
                      label: location,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSportIconPath(String activityName) {
    final activity = activityName.toLowerCase();

    if (activity.contains('table tennis')) return AppAssets.tableTennis;
    if (activity.contains('football turf')) return AppAssets.footballTurf;
    if (activity.contains('box cricket')) return AppAssets.boxCricket;
    if (activity.contains('cricket net')) return AppAssets.cricketNets;
    if (activity.contains('cricket turf') ||
        activity.contains('turf cricket') ||
        activity.contains('cricket')) {
      return AppAssets.cricketTurf;
    }
    if (activity.contains('football')) return AppAssets.football;
    if (activity.contains('basketball')) return AppAssets.basketball;
    if (activity.contains('tennis') && !activity.contains('table')) {
      return AppAssets.tennis;
    }
    if (activity.contains('badminton')) return AppAssets.badminton;
    if (activity.contains('volleyball')) return AppAssets.volleyball;
    if (activity.contains('pool') && !activity.contains('swimming')) {
      return AppAssets.pool;
    }
    if (activity.contains('snooker')) return AppAssets.snooker;
    if (activity.contains('swimming')) return AppAssets.swimming;
    if (activity.contains('gym')) return AppAssets.gym;
    if (activity.contains('yoga')) return AppAssets.yoga;
    if (activity.contains('adventure sports')) {
      return AppAssets.adventureSports;
    }
    if (activity.contains('archery')) return AppAssets.archery;
    if (activity.contains('bouldering')) return AppAssets.bouldering;
    if (activity.contains('bowling')) return AppAssets.bowling;
    if (activity.contains('boxing')) return AppAssets.boxing;
    if (activity.contains('crossfit')) return AppAssets.crossfit;
    if (activity.contains('dance')) return AppAssets.dance;
    if (activity.contains('equestrian')) return AppAssets.equestrian;
    if (activity.contains('frisbee')) return AppAssets.frisbee;
    if (activity.contains('hiit')) return AppAssets.hiit;
    if (activity.contains('hockey')) return AppAssets.hockey;
    if (activity.contains('marshal art') || activity.contains('martial')) {
      return AppAssets.martialArts;
    }
    if (activity.contains('mma')) return AppAssets.mma;
    if (activity.contains('padbol')) return AppAssets.padbol;
    if (activity.contains('padel')) return AppAssets.padel;
    if (activity.contains('paintball')) return AppAssets.paintball;
    if (activity.contains('pickleball')) return AppAssets.pickleball;
    if (activity.contains('pilates')) return AppAssets.pilates;
    if (activity.contains('rock climbing')) return AppAssets.rockClimbing;
    if (activity.contains('shooting')) return AppAssets.shooting;
    if (activity.contains('skating')) return AppAssets.skating;
    if (activity.contains('squash')) return AppAssets.squash;
    if (activity.contains('teqball')) return AppAssets.teqball;
    if (activity.contains('trampoline')) return AppAssets.trampoline;

    return AppAssets.otherSport;
  }
}

class _IconText extends StatelessWidget {
  final String iconPath;
  final String label;

  const _IconText({
    required this.iconPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryIcon(iconPath: iconPath),
        const SizedBox(width: 4),
        Expanded(
          child: AppText(
            label,
            color: AppColors.grey99,
            fontSize: 16,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _SummaryIcon extends StatelessWidget {
  final String iconPath;

  const _SummaryIcon({
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    if (iconPath.toLowerCase().endsWith('.svg')) {
      return AppSvg(
        iconPath,
        width: 16,
        height: 16,
        color: AppColors.grey99,
      );
    }

    return Image.asset(
      iconPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
    );
  }
}
