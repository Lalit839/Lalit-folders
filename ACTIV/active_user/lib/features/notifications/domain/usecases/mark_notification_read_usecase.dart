import 'package:activ_user_app/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  const MarkNotificationReadUseCase(this.repository);

  Future<void> call(String id) {
    return repository.markAsRead(id);
  }
}
