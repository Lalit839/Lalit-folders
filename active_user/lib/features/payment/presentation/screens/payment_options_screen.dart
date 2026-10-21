import 'dart:async';

import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/payment/presentation/models/payment_method_option.dart';
import 'package:activ_user_app/features/payment/presentation/screens/add_new_card_screen.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class PaymentOptionsScreen extends StatefulWidget {
  final int amountRupees;
  final DateTime? expiresAt;
  final PaymentMethodOption selectedMethod;
  final bool startPaymentOnSelection;

  const PaymentOptionsScreen({
    super.key,
    required this.amountRupees,
    required this.expiresAt,
    required this.selectedMethod,
    this.startPaymentOnSelection = false,
  });

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  late PaymentMethodOption _selected = widget.selectedMethod;

  List<PaymentMethodOption> get _recommendedMethods {
    return const [
      PaymentMethodOption.googlePay,
      PaymentMethodOption.phonePe,
      PaymentMethodOption.paytm,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _PaymentShell(
      title: 'Payment Options',
      amountRupees: widget.amountRupees,
      expiresAt: widget.expiresAt,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          AppText.bold(
            'Recommended',
            color: AppColors.greyBorder,
            fontSize: 18,
          ),
          const SizedBox(height: 14),
          for (final method in _recommendedMethods) ...[
            _PaymentMethodTile(
              method: method,
              selected: _selected.id == method.id,
              onTap: () => _choose(
                method,
                shouldStartPayment: widget.startPaymentOnSelection,
              ),
              onPayTap: () => _choose(method, shouldStartPayment: true),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 28),
          const Divider(color: AppColors.lightGreyBorder),
          const SizedBox(height: 36),
          AppText.bold(
            'Saved Cards',
            color: AppColors.greyBorder,
            fontSize: 18,
          ),
          const SizedBox(height: 14),
          _SavedCardTile(
            title: 'Yes bank 3455',
            subtitle: 'Debit card',
            color: const Color(0xFF154DE8),
            marker: 'Y',
            onTap: () => _choose(
              PaymentMethodOption.card,
              shouldStartPayment: widget.startPaymentOnSelection,
            ),
          ),
          const SizedBox(height: 12),
          _SavedCardTile(
            title: 'Bank of baroda 8789',
            subtitle: 'Credit card',
            color: AppColors.white,
            marker: 'B',
            markerColor: const Color(0xFFE95E24),
            onTap: () => _choose(
              PaymentMethodOption.card,
              shouldStartPayment: widget.startPaymentOnSelection,
            ),
          ),
          const SizedBox(height: 24),
          _AddCardButton(
            onTap: () async {
              final result = await Navigator.push<PaymentMethodOption>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNewCardScreen(
                    amountRupees: widget.amountRupees,
                    expiresAt: widget.expiresAt,
                  ),
                ),
              );
              if (result != null && mounted) {
                _choose(
                  result,
                  shouldStartPayment: widget.startPaymentOnSelection,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _choose(PaymentMethodOption method, {required bool shouldStartPayment}) {
    setState(() => _selected = method);
    Navigator.pop(
      context,
      PaymentSelectionResult(
        method: method,
        shouldStartPayment: shouldStartPayment,
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPayTap;

  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    required this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = selected && method.id == PaymentMethodOption.googlePay.id;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.yellowDark : AppColors.blackColor2,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            _MethodLogo(method: method),
            const SizedBox(width: 12),
            Expanded(
              child: AppText.medium(
                method.title,
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 17,
              ),
            ),
            if (isPrimary)
              GestureDetector(
                onTap: onPayTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: AppText.bold(
                    'Pay',
                    color: AppColors.black,
                    fontSize: 16,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _MethodLogo extends StatelessWidget {
  final PaymentMethodOption method;

  const _MethodLogo({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method.id == 'google_pay_upi') {
      return const SizedBox(width: 40, height: 40, child: _GooglePayMark());
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: method.id == 'phonepe_upi'
            ? const Color(0xFF6739B7)
            : AppColors.white,
        shape: BoxShape.circle,
      ),
      child: AppText.bold(
        method.id == 'phonepe_upi' ? 'P' : 'paytm',
        color: method.id == 'phonepe_upi'
            ? AppColors.white
            : const Color(0xFF00BAF2),
        fontSize: method.id == 'paytm_upi' ? 11 : 18,
        maxLines: 1,
      ),
    );
  }
}

class _GooglePayMark extends StatelessWidget {
  const _GooglePayMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.7,
          child: Container(
            width: 12,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(7, 0),
          child: Transform.rotate(
            angle: 0.65,
            child: Container(
              width: 12,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF34A853),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(-1, -8),
          child: Transform.rotate(
            angle: 0.65,
            child: Container(
              width: 10,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFBBC04),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(1, 8),
          child: Transform.rotate(
            angle: 0.65,
            child: Container(
              width: 10,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFEA4335),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String marker;
  final Color markerColor;
  final VoidCallback onTap;

  const _SavedCardTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.marker,
    required this.onTap,
    this.markerColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blackColor2,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: AppText.bold(marker, color: markerColor, fontSize: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.medium(title, color: AppColors.textPrimary),
                  AppText(subtitle, color: AppColors.grey99, fontSize: 12),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGreyBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.greyBorder),
            const SizedBox(width: 8),
            AppText.bold(
              'Add New card',
              color: AppColors.greyBorder,
              fontSize: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentShell extends StatelessWidget {
  final String title;
  final int amountRupees;
  final DateTime? expiresAt;
  final Widget child;

  const _PaymentShell({
    required this.title,
    required this.amountRupees,
    required this.expiresAt,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppText(
                      title,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  _AmountTimerPill(
                    amountRupees: amountRupees,
                    expiresAt: expiresAt,
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AmountTimerPill extends StatefulWidget {
  final int amountRupees;
  final DateTime? expiresAt;

  const _AmountTimerPill({required this.amountRupees, required this.expiresAt});

  @override
  State<_AmountTimerPill> createState() => _AmountTimerPillState();
}

class _AmountTimerPillState extends State<_AmountTimerPill> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final expiresAt = widget.expiresAt;
    final next = expiresAt == null
        ? Duration.zero
        : expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = next.isNegative ? Duration.zero : next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGreyBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: AppText.bold('₹${widget.amountRupees}', fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blackColor3,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText.bold(
              '$minutes:$seconds',
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
