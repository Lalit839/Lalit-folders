import 'package:flutter/foundation.dart';
import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:activ_user_app/features/notifications/presentation/state/notification_state.dart';

class NotificationController extends ValueNotifier<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  NotificationController({
    required this.getNotificationsUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.deleteNotificationUseCase,
  }) : super(NotificationState.initial());

  Future<void> fetchNotifications() async {
    value = value.copyWith(isLoading: true);
    try {
      final notifications = await getNotificationsUseCase();
      // Sort: newest first
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      value = value.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      value = value.copyWith(
        errorMessage: 'Failed to load notifications: $e',
        isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    final index = value.notifications.indexWhere((e) => e.id == id);
    if (index == -1 || value.notifications[index].isRead) return;

    final originalList = List<NotificationEntity>.from(value.notifications);
    final updatedList = List<NotificationEntity>.from(value.notifications);
    updatedList[index] = updatedList[index].copyWith(isRead: true);

    value = value.copyWith(notifications: updatedList);

    try {
      await markNotificationReadUseCase(id);
    } catch (e) {
      // Revert if API fails
      value = value.copyWith(notifications: originalList);
    }
  }

  Future<void> markAllAsRead() async {
    if (value.notifications.every((e) => e.isRead)) return;

    final originalList = List<NotificationEntity>.from(value.notifications);
    final updatedList = value.notifications
        .map((e) => e.copyWith(isRead: true))
        .toList();

    value = value.copyWith(notifications: updatedList);

    try {
      await markAllNotificationsReadUseCase();
    } catch (e) {
      value = value.copyWith(notifications: originalList);
    }
  }

  Future<void> deleteNotification(String id) async {
    final originalList = List<NotificationEntity>.from(value.notifications);
    final updatedList = List<NotificationEntity>.from(value.notifications)
      ..removeWhere((e) => e.id == id);

    value = value.copyWith(notifications: updatedList);

    try {
      await deleteNotificationUseCase(id);
    } catch (e) {
      value = value.copyWith(notifications: originalList);
    }
  }

  Map<String, List<NotificationEntity>> getGroupedNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<NotificationEntity>> groups = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Older': [],
    };

    for (final notification in value.notifications) {
      final date = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day);

      if (date.isAtSameMomentAs(today)) {
        groups['Today']!.add(notification);
      } else if (date.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(notification);
      } else if (date.isAfter(sevenDaysAgo)) {
        groups['This Week']!.add(notification);
      } else {
        groups['Older']!.add(notification);
      }
    }

    // Clean up empty categories
    groups.removeWhere((key, list) => list.isEmpty);
    return groups;
  }
}
