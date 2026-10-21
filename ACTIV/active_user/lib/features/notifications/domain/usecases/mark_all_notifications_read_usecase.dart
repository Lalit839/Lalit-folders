import 'package:activ_user_app/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationRepository repository;

  const MarkAllNotificationsReadUseCase(this.repository);

  Future<void> call() {
    return repository.markAllAsRead();
  }
}
