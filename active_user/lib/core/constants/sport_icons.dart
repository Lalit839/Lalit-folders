import 'package:activ_user_app/core/constants/app_assets.dart';

const List<Map<String, String>> assetSportCategories = [
  {'label': 'Gym', 'sportCode': 'gym', 'iconPath': AppAssets.gym},
  {'label': 'Yoga', 'sportCode': 'yoga', 'iconPath': AppAssets.yoga},
  {'label': 'Pilates', 'sportCode': 'pilates', 'iconPath': AppAssets.pilates},
  {'label': 'Zumba', 'sportCode': 'zumba', 'iconPath': AppAssets.dance},
  {'label': 'Dance', 'sportCode': 'dance', 'iconPath': AppAssets.dance},
  {'label': 'CrossFit', 'sportCode': 'crossfit', 'iconPath': AppAssets.crossfit},
  {'label': 'HIIT', 'sportCode': 'hiit', 'iconPath': AppAssets.hiit},
  {'label': 'Bowling', 'sportCode': 'bowling', 'iconPath': AppAssets.bowling},
  {'label': 'Trampoline', 'sportCode': 'trampoline', 'iconPath': AppAssets.trampoline},
  {'label': 'Adventure Sports', 'sportCode': 'adventure', 'iconPath': AppAssets.adventureSports},
  {'label': 'Rock Climbing', 'sportCode': 'rock_climbing', 'iconPath': AppAssets.rockClimbing},
  {'label': 'Bouldering', 'sportCode': 'bouldering', 'iconPath': AppAssets.bouldering},
  {'label': 'Boxing', 'sportCode': 'boxing', 'iconPath': AppAssets.boxing},
  {'label': 'MMA', 'sportCode': 'mma', 'iconPath': AppAssets.mma},
  {'label': 'Martial Arts', 'sportCode': 'martial_arts', 'iconPath': AppAssets.martialArts},
  {'label': 'Archery', 'sportCode': 'archery', 'iconPath': AppAssets.archery},
  {'label': 'Shooting', 'sportCode': 'shooting', 'iconPath': AppAssets.shooting},
  {'label': 'Swimming', 'sportCode': 'swimming', 'iconPath': AppAssets.swimming},
  {'label': 'Skating', 'sportCode': 'skating', 'iconPath': AppAssets.skating},
  {'label': 'Equestrian', 'sportCode': 'equestrian', 'iconPath': AppAssets.equestrian},
  {'label': 'Badminton', 'sportCode': 'badminton', 'iconPath': AppAssets.badminton},
  {'label': 'Tennis', 'sportCode': 'tennis', 'iconPath': AppAssets.tennis},
  {'label': 'Pickleball', 'sportCode': 'pickleball', 'iconPath': AppAssets.pickleball},
  {'label': 'Padel', 'sportCode': 'padel', 'iconPath': AppAssets.padel},
  {'label': 'Squash', 'sportCode': 'squash', 'iconPath': AppAssets.squash},
  {'label': 'Basketball', 'sportCode': 'basketball', 'iconPath': AppAssets.basketball},
  {'label': 'Volleyball', 'sportCode': 'volleyball', 'iconPath': AppAssets.volleyball},
  {'label': 'Padbol', 'sportCode': 'padbol', 'iconPath': AppAssets.padbol},
  {'label': 'Table Tennis', 'sportCode': 'table_tennis', 'iconPath': AppAssets.tableTennis},
  {'label': 'Pool Table', 'sportCode': 'pool', 'iconPath': AppAssets.pool},
  {'label': 'Snooker', 'sportCode': 'snooker', 'iconPath': AppAssets.snooker},
  {'label': 'Teqball', 'sportCode': 'teqball', 'iconPath': AppAssets.teqball},
  {'label': 'Cricket Turf', 'sportCode': 'cricket_turf', 'iconPath': AppAssets.cricketTurf},
  {'label': 'Football', 'sportCode': 'football', 'iconPath': AppAssets.football},
  {'label': 'Football Turf', 'sportCode': 'football_turf', 'iconPath': AppAssets.footballTurf},
  {'label': 'Hockey', 'sportCode': 'hockey', 'iconPath': AppAssets.hockey},
  {'label': 'Paintball', 'sportCode': 'paintball', 'iconPath': AppAssets.paintball},
  {'label': 'Frisbee', 'sportCode': 'frisbee', 'iconPath': AppAssets.frisbee},
  {'label': 'Cricket Nets', 'sportCode': 'cricket_nets', 'iconPath': AppAssets.cricketNets},
  {'label': 'Box Cricket', 'sportCode': 'box_cricket', 'iconPath': AppAssets.boxCricket},
];

List<Map<String, String>> mergeAssetSportCategories(
  Iterable<Map<String, String>> remoteCategories,
) {
  final byCode = {
    for (final category in assetSportCategories)
      normalizeSportCode(category['sportCode']): Map<String, String>.from(category),
  };

  for (final remote in remoteCategories) {
    final label = remote['label']?.trim() ?? '';
    final code = normalizeSportCode(remote['sportCode'] ?? label);
    if (code.isEmpty) continue;

    final existing = byCode[code];
    byCode[code] = {
      if (existing != null) ...existing,
      ...remote,
      'label': label.isNotEmpty ? label : existing?['label'] ?? code,
      'sportCode': remote['sportCode'] ?? existing?['sportCode'] ?? code,
      'iconPath': iconForSport(remote['sportCode'] ?? label),
      'iconUrl': '',
    };
  }

  return byCode.values
      .map((category) => {
            'label': category['label'] ?? '',
            'sportCode': category['sportCode'] ?? '',
            'iconPath': category['iconPath'] ?? iconForSport(category['sportCode']),
            'iconUrl': category['iconUrl'] ?? '',
          })
      .where((category) => category['label']!.isNotEmpty)
      .toList(growable: false);
}

String normalizeSportCode(String? code) {
  final normalized = (code ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
  return switch (normalized) {
    'football_ground' || 'football_turf' => 'football_turf',
    'cricket' || 'turf_cricket' || 'cricket_turf' => 'cricket_turf',
    'cricket_net' || 'cricket_nets' => 'cricket_nets',
    'boxcricket' || 'box_cricket' => 'box_cricket',
    'pool' || 'pool_table' || 'billiards' => 'pool',
    'tabletennis' || 'table_tennis' => 'table_tennis',
    'martial_art' || 'martial_arts' || 'marshal_art' => 'martial_arts',
    'adventure' || 'adventure_sports' => 'adventure',
    'rockclimbing' || 'rock_climbing' => 'rock_climbing',
    'yoga_studio' => 'yoga',
    'dance_studio' => 'dance',
    'hiit_studio' => 'hiit',
    _ => normalized,
  };
}

String iconForSport(String? code) => switch (normalizeSportCode(code)) {
      'football' => AppAssets.football,
      'football_turf' => AppAssets.footballTurf,
      'cricket_turf' => AppAssets.cricketTurf,
      'cricket_nets' => AppAssets.cricketNets,
      'box_cricket' => AppAssets.boxCricket,
      'tennis' => AppAssets.tennis,
      'squash' => AppAssets.squash,
      'table_tennis' => AppAssets.tableTennis,
      'badminton' => AppAssets.badminton,
      'basketball' => AppAssets.basketball,
      'volleyball' => AppAssets.volleyball,
      'pickleball' => AppAssets.pickleball,
      'padel' => AppAssets.padel,
      'padbol' => AppAssets.padbol,
      'pool' => AppAssets.pool,
      'snooker' => AppAssets.snooker,
      'teqball' => AppAssets.teqball,
      'gym' => AppAssets.gym,
      'yoga' => AppAssets.yoga,
      'pilates' => AppAssets.pilates,
      'crossfit' => AppAssets.crossfit,
      'zumba' => AppAssets.otherSport,
      'dance' => AppAssets.dance,
      'hiit' => AppAssets.hiit,
      'bowling' => AppAssets.bowling,
      'trampoline' => AppAssets.trampoline,
      'adventure' => AppAssets.adventureSports,
      'rock_climbing' => AppAssets.rockClimbing,
      'bouldering' => AppAssets.bouldering,
      'boxing' => AppAssets.boxing,
      'mma' => AppAssets.mma,
      'martial_arts' => AppAssets.martialArts,
      'archery' => AppAssets.archery,
      'shooting' => AppAssets.shooting,
      'swimming' => AppAssets.swimming,
      'skating' => AppAssets.skating,
      'equestrian' => AppAssets.equestrian,
      'hockey' => AppAssets.hockey,
      'paintball' => AppAssets.paintball,
      'frisbee' => AppAssets.frisbee,
      _ => AppAssets.otherSport,
    };
