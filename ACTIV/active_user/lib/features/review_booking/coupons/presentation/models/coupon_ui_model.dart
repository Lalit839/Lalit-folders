class CouponUiModel {
  final String id;
  final String code;
  final String description;
  final double minOrderValue;
  final double discountAmount;
  final DateTime expiryDate;

  const CouponUiModel({
    required this.id,
    required this.code,
    required this.description,
    required this.minOrderValue,
    required this.discountAmount,
    required this.expiryDate,
  });

  bool get isFlatDiscount => discountAmount > 0;

  String get title {
    if (isFlatDiscount) {
      return 'Get Flat \u20B9${discountAmount.toInt()} OFF';
    }
    if (description.trim().isEmpty) return 'Get a discount';
    return 'Get ${description.trim()}';
  }

  String get subtitle {
    if (isFlatDiscount) return 'Save \u20B9${discountAmount.toInt()} with this code';
    return 'Auto-applied at checkout';
  }
}
