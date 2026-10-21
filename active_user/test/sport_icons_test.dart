import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/sport_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sport icon catalog', () {
    test('contains local asset-backed sports for the home strip', () {
      expect(assetSportCategories.length, greaterThan(30));
      expect(
        assetSportCategories,
        contains(
          {'label': 'Badminton', 'sportCode': 'badminton', 'iconPath': AppAssets.badminton},
        ),
      );
      expect(
        assetSportCategories,
        contains(
          {'label': 'Cricket Nets', 'sportCode': 'cricket_nets', 'iconPath': AppAssets.cricketNets},
        ),
      );
    });

    test('normalizes code, name, hyphen, and spaced variants', () {
      expect(iconForSport('football-turf'), AppAssets.footballTurf);
      expect(iconForSport('Football Turf'), AppAssets.footballTurf);
      expect(iconForSport('Pool Table'), AppAssets.pool);
      expect(iconForSport('Martial Arts'), AppAssets.martialArts);
    });

    test('keeps all asset sports when backend activities are empty', () {
      final merged = mergeAssetSportCategories(const <Map<String, String>>[]);

      expect(merged.length, assetSportCategories.length);
      expect(merged.first['iconPath'], isNotEmpty);
      expect(merged.every((category) => category['iconPath']!.isNotEmpty), isTrue);
    });

    test('uses local icons when merging backend activities', () {
      final merged = mergeAssetSportCategories([
        {
          'label': 'Football Turf',
          'sportCode': 'football_turf',
          'iconPath': '',
          'iconUrl': 'https://example.com/icon.svg',
        },
      ]);
      final football = merged.firstWhere(
        (category) => category['sportCode'] == 'football_turf',
      );

      expect(football['iconPath'], AppAssets.footballTurf);
      expect(football['iconUrl'], isEmpty);
    });
  });
}
