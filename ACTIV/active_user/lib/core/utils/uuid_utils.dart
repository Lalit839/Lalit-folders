bool isValidUuid(String? value) {
  if (value == null || value.isEmpty) {
    return false;
  }

  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  return uuidRegex.hasMatch(value);
}