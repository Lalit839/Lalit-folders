import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;

  const NotificationState({
    required this.notifications,
    required this.isLoading,
    required this.isUpdating,
    this.errorMessage,
  });

  factory NotificationState.initial() {
    return const NotificationState(
      notifications: [],
      isLoading: true,
      isUpdating: false);
  }

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage);
  }
}
