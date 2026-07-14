import '../domain/notification.dart';
import '../domain/notification_broadcast.dart';

NotificationEntity notificationFromJson(dynamic json) {
  if (json is! Map<String, dynamic>) {
    return NotificationEntity(
      id: '',
      type: NotificationType.system,
      title: '',
      message: '',
      createdAt: DateTime.now(),
    );
  }

  return NotificationEntity(
    id: json['id']?.toString() ?? '',
    type: NotificationType.fromString(json['type']?.toString() ?? 'SYSTEM'),
    title: json['title']?.toString() ?? '',
    message: (json['body'] ?? json['message'] ?? '').toString(),
    createdAt: _toDateTime(json['createdAt']),
    isRead: _toBool(json['isRead'] ?? json['read']),
    relatedOrderId: _toOptionalString(json['relatedOrderId']),
    relatedProductId: _toOptionalString(json['relatedProductId']),
    relatedChatRoomId: _toOptionalString(json['relatedChatRoomId']),
  );
}

List<NotificationEntity> notificationsFromJson(dynamic json) {
  if (json is! List) {
    return const [];
  }
  return json.map(notificationFromJson).toList();
}

NotificationBroadcast broadcastFromJson(dynamic json) {
  final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
  return NotificationBroadcast(
    broadcastId: map['broadcastId']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    body: map['body']?.toString() ?? '',
    createdBy: _toOptionalString(map['createdBy']),
    createdAt: _toDateTime(map['createdAt']),
    recipientCount: _toInt(map['recipientCount']),
  );
}

List<NotificationBroadcast> broadcastsFromJson(dynamic json) {
  if (json is! List) {
    return const [];
  }
  return json.map(broadcastFromJson).toList();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _toOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}
