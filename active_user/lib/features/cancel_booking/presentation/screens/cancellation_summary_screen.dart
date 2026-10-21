import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/shared/widgets/app_card.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/shared/widgets/success_bottom_sheet.dart';
import 'package:intl/intl.dart';

class CancellationSummaryScreen extends StatelessWidget {
  const CancellationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final result = args?['result'] as Map<String, dynamic>? ?? {};
    final paid = int.tryParse('${args?['paidAmount']}') ?? 0;
    final refundMap = result['refund'];
    final refund = refundMap is Map<String, dynamic>
        ? (int.tryParse('${refundMap['amountPaise']}') ?? 0)
        : 0;
    final serviceFee = (paid - refund).clamp(0, paid).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Refund Summary'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPriceBreakdownCard(paid, serviceFee, refund),
              const SizedBox(height: 16),
              _buildRefundableAmountBox(refund),
              const SizedBox(height: 40),
              AppButton(
                title: 'Cancel My Booking',
                onTap: () {
                  showSuccessBottomSheet(
                    context: context,
                    title: 'Cancellation Successful',
                    subtitle: 'Your Court is Cancelled. Refundable money will credit your selected wallet',
                    topPillText: 'Successful',
                    primaryButtonText: 'Track Refund Amount',
                    onPrimaryButtonTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.bookingDetails,
                        (route) => route.isFirst,
                        arguments: {
                          'status': 'CANCELLED',
                          'bookingId': args?['bookingId'],
                        },
                      );
                    },
                    secondaryButtonText: 'Back to Home',
                    onSecondaryButtonTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                },
                backgroundColor: AppColors.blackColor2,
                textColor: AppColors.primary,
                showArrow: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _inr(dynamic paise) =>
      '₹${NumberFormat('#,##0').format((num.tryParse('$paise') ?? 0) / 100)}';

  Widget _buildPriceBreakdownCard(
    int paid,
    int serviceFee,
    int refund,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bold(
            'Price Breakdown',
            color: AppColors.greyBorder,
            fontSize: 18,
          ),
          const AppDivider(verticalPadding: 12),
          _buildRow('Amount Paid', _inr(paid), AppColors.greyBorder),
          if (serviceFee > 0) ...[
            const SizedBox(height: 12),
            _buildRow('Service Fee', '-${_inr(serviceFee)}', AppColors.errorRed2),
          ],
          const AppDivider(verticalPadding: 12),
          _buildRow(
            'Cancelled Slot Price',
            _inr(refund),
            AppColors.textPrimary,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRefundableAmountBox(int refund) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellowDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bold(
            'Refundable Amount',
            color: AppColors.primary,
            fontSize: 18,
          ),
          AppText.bold(_inr(refund), color: AppColors.primary, fontSize: 18),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isBold)
          AppText.medium(label, color: valueColor, fontSize: 18)
        else
          AppText.small(label, color: AppColors.greyBorder, fontSize: 18),

        AppText.medium(value, color: valueColor, fontSize: 18),
      ],
    );
  }
}