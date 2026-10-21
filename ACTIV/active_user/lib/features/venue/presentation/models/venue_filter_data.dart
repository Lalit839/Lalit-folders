class VenueFilterData {
  static const List<String> sortOptions = [
    'Price Low to High',
    'Price High to Low',
    'Popular',
    'Rating High to Low',
  ];

  static const List<String> distanceOptions = [
    'Under 0.5 km',
    'Under 2.0 km',
    'Under 5.0 km',
    'Under 10 km',
  ];

  static const List<String> ratingOptions = [
    '4.5 and above',
    '4.0 and above',
    '3.5 and above',
    '3.0 and above',
  ];

  static const List<String> activityTypeOptions = [
    'Solo',
    'Friends & Family',
    'Team sport',
  ];

  static const Map<String, List<String>> activityTypeValues = {
    'Solo': ['single'],
    'Friends & Family': ['court', 'table'],
    'Team sport': ['turf', 'cricket nets'],
  };
}
