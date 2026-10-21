String venueDiscountText(Map<String, dynamic> venue) {
  for (final key in const [
    'discount',
    'offer',
    'discountText',
    'discountPercent',
    'percentOff',
  ]) {
    final text = _discountTextFromValue(venue[key]);
    if (text.isNotEmpty) return text;
  }

  final offers = venue['offers'];
  if (offers is Iterable) {
    for (final offer in offers) {
      if (offer is! Map) continue;
      for (final key in const ['discount', 'title', 'description']) {
        final text = _discountTextFromValue(offer[key]);
        if (text.isNotEmpty) return text;
      }
    }
  }

  return '';
}

String _discountTextFromValue(Object? value) {
  if (value == null) return '';

  if (value is num && value > 0) {
    return '${_formatNumber(value)}% OFF';
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return '';

  final percent = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(raw);
  if (percent != null) return '${percent.group(1)}% OFF';

  final numeric = num.tryParse(raw);
  if (numeric != null && numeric > 0) {
    return '${_formatNumber(numeric)}% OFF';
  }

  return raw.toUpperCase();
}

String _formatNumber(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toString();
}
