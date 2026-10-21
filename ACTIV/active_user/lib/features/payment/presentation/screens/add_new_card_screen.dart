import 'dart:async';

import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/payment/presentation/models/payment_method_option.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AddNewCardScreen extends StatelessWidget {
  final int amountRupees;
  final DateTime? expiresAt;

  const AddNewCardScreen({
    super.key,
    required this.amountRupees,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return _PaymentCountdownScaffold(
      title: 'Add new card',
      amountRupees: amountRupees,
      expiresAt: expiresAt,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'We accept credit and debit cards from visa, mastercard, rupay & american express',
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.35,
            ),
            const SizedBox(height: 32),
            _SecureCardLine(label: 'Cardholder name'),
            const SizedBox(height: 24),
            _SecureCardLine(label: 'Card Number'),
            const SizedBox(height: 24),
            _SecureCardLine(label: 'Expiry date (MM/YY)'),
            const SizedBox(height: 24),
            _SecureCardLine(label: 'CVV'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context, PaymentMethodOption.card),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.blackColor3,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: AppText.bold('Continue securely', fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SecureCardLine extends StatelessWidget {
  final String label;

  const _SecureCardLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, color: AppColors.grey99, fontSize: 16),
        const SizedBox(height: 10),
        Container(height: 1, color: AppColors.grey99),
      ],
    );
  }
}

class _PaymentCountdownScaffold extends StatelessWidget {
  final String title;
  final int amountRupees;
  final DateTime? expiresAt;
  final Widget child;

  const _PaymentCountdownScaffold({
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
