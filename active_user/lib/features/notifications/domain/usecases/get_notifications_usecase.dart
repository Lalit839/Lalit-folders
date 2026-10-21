import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:activ_user_app/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  const GetNotificationsUseCase(this.repository);

  Future<List<NotificationEntity>> call() {
    return repository.getNotifications();
  }
}
