import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) {
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final ampm = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } else if (diffDays == 1) {
      return '1 day ago';
    } else {
      return '$diffDays days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    String iconAsset;

    switch (notification.type) {
      case NotificationType.booking:
        if (notification.title.toLowerCase().contains('completed')) {
          iconAsset = AppAssets.notifyBookingCompleted;
        } else if (notification.title.toLowerCase().contains('reschedule')) {
          if (notification.id == '4') {
            // just to match the blue one in mock
            iconAsset = AppAssets.notifyBell;
          } else {
            iconAsset = AppAssets.notifyVenueRescheduled;
          }
        } else if (notification.title.toLowerCase().contains('cancelled')) {
          iconAsset = AppAssets.notifyBookingCancelled;
        } else {
          // Confirmed
          iconAsset = AppAssets.notifyBookingConfirmed;
        }
        break;
      case NotificationType.offer:
        iconAsset = AppAssets.notifyNewOffer;
        break;
      case NotificationType.alert:
      case NotificationType.general:
        // Use for payment / refund depending on title
        if (notification.title.toLowerCase().contains('payment')) {
          if (notification.title.toLowerCase().contains('failed')) {
            iconAsset = AppAssets.notifyPaymentFailed;
          } else {
            iconAsset = AppAssets.notifyPaymentSuccessful;
          }
        } else if (notification.title.toLowerCase().contains('refund')) {
          if (notification.title.toLowerCase().contains('completed')) {
            iconAsset = AppAssets.notifyRefundCompleted;
          } else {
            iconAsset = AppAssets.notifyRefundInitiated;
          }
        } else {
          iconAsset = AppAssets.notifyBell;
        }
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSvg(iconAsset, width: 42, height: 42),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppText.medium(
                            notification.title,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        AppText.small(
                          _formatTime(notification.timestamp),
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppText.small(
                            notification.body,
                            fontSize: 12,
                            color: AppColors.grey99,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
