import 'package:activ_user_app/features/notifications/domain/repositories/notification_repository.dart';

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  const DeleteNotificationUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteNotification(id);
  }
}
