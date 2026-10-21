class RazorpayWebResult {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  const RazorpayWebResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

Future<void> openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required void Function(RazorpayWebResult result) onSuccess,
  required void Function(String message) onFailure,
}) async {
  throw UnsupportedError('Razorpay web checkout is only available on web.');
}
