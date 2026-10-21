class PriceBreakdownUiModel {
  final double slotPrice;
  final double serviceFee;
  final double discount;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;

  const PriceBreakdownUiModel({
    required this.slotPrice,
    required this.serviceFee,
    required this.discount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
  });

  double get subtotal => slotPrice + serviceFee - discount.abs();
}
