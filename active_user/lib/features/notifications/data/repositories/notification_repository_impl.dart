import 'package:activ_user_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:activ_user_app/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource dataSource;

  const NotificationRepositoryImpl(this.dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    return dataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String id) {
    return dataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return dataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String id) {
    return dataSource.deleteNotification(id);
  }
}
