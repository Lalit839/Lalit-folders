enum PaymentMethodType { upi, wallet, card }

class PaymentMethodOption {
  final String id;
  final String title;
  final String subtitle;
  final PaymentMethodType type;
  final String? wallet;
  final String? upiAppPackageName;

  const PaymentMethodOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.wallet,
    this.upiAppPackageName,
  });

  static const googlePay = PaymentMethodOption(
    id: 'google_pay_upi',
    title: 'Google Pay UPI',
    subtitle: 'UPI',
    type: PaymentMethodType.upi,
    upiAppPackageName: 'com.google.android.apps.nbu.paisa.user',
  );

  static const phonePe = PaymentMethodOption(
    id: 'phonepe_upi',
    title: 'PhonePe UPI',
    subtitle: 'UPI',
    type: PaymentMethodType.upi,
    upiAppPackageName: 'com.phonepe.app',
  );

  static const paytm = PaymentMethodOption(
    id: 'paytm_upi',
    title: 'Paytm',
    subtitle: 'UPI',
    type: PaymentMethodType.upi,
    upiAppPackageName: 'net.one97.paytm',
  );

  static const card = PaymentMethodOption(
    id: 'secure_card',
    title: 'Credit / Debit Card',
    subtitle: 'Secured by Razorpay',
    type: PaymentMethodType.card,
  );

  String get checkoutMethod => switch (type) {
    PaymentMethodType.upi => 'upi',
    PaymentMethodType.wallet => 'wallet',
    PaymentMethodType.card => 'card',
  };
}

class PaymentSelectionResult {
  final PaymentMethodOption method;
  final bool shouldStartPayment;

  const PaymentSelectionResult({
    required this.method,
    required this.shouldStartPayment,
  });
}
