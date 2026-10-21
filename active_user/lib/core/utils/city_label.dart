String cityLabel(String? code) {
  final normalized = (code ?? '').trim().toUpperCase();
  return switch (normalized) {
    'IND' => 'Indore, India',
    'DEL' => 'Delhi, India',
    'BOM' => 'Mumbai, India',
    'BLR' => 'Bengaluru, India',
    'HYD' => 'Hyderabad, India',
    'PUN' => 'Pune, India',
    _ => code?.trim() ?? '',
  };
}

String venueLocationLabel(Map<String, dynamic> json) {
  for (final key in const [
    'address',
    'fullAddress',
    'location',
    'locality',
    'area',
    'city',
  ]) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toUpperCase() != value) return value;
  }
  return cityLabel(json['cityCode']?.toString());
}
