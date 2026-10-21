import 'package:activ_user_app/features/notifications/data/models/notification_model.dart';

class NotificationResponseModel {
  final List<NotificationModel> notifications;

  const NotificationResponseModel({required this.notifications});

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List? ?? [];
    return NotificationResponseModel(
      notifications: list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((e) => e.toJson()).toList(),
    };
  }
}
