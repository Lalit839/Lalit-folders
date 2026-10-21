import 'package:activ_user_app/features/notifications/data/models/notification_model.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
}

class ApiNotificationRemoteDataSource implements NotificationRemoteDataSource {
  const ApiNotificationRemoteDataSource();

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final items = await ActivApiClient.instance.getNotifications();
    return items.whereType<Map<String, dynamic>>().map(NotificationModel.fromJson).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await ActivApiClient.instance.markNotificationRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await ActivApiClient.instance.markAllNotificationsRead();
  }

  @override
  Future<void> deleteNotification(String id) async {
    await ActivApiClient.instance.deleteNotification(id);
  }
}