import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.timestamp,
    required super.isRead,
    required super.type,
    super.targetType,
    super.targetId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json['payload'] ?? json['metadata']) is Map
        ? (json['data'] ?? json['payload'] ?? json['metadata'])
            as Map<String, dynamic>
        : null;

    String? firstString(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is num) return value.toString();
      }
      return null;
    }

    String? targetType =
        firstString(json, ['targetType', 'target_type', 'screen', 'entityType', 'entity_type'])
            ??
            firstString(data ?? {}, [
              'targetType',
              'entityType',
              'entity_type',
            ]);

    String? targetId =
        firstString(json, ['targetId', 'target_id', 'bookingId', 'booking_id', 'entityId', 'entity_id'])
            ??
            firstString(data ?? {}, [
              'targetId',
              'bookingId',
              'booking_id',
              'entityId',
              'entity_id',
              'id',
            ]);

    final typeName =
        (json['type']?.toString().toLowerCase() ?? '') +
        (targetType?.toLowerCase() ?? '');
    if (targetId != null && typeName.contains('book') && targetType == null) {
      targetType = 'booking';
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
timestamp: DateTime.tryParse((json['createdAt'] ?? json['timestamp']).toString()) ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? json['readAt'] != null,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type']?.toString().toLowerCase(),
        orElse: () => NotificationType.general),
      targetType: targetType,
      targetId: targetId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      if (targetType != null) 'targetType': targetType,
      if (targetId != null) 'targetId': targetId,
    };
  }
}
