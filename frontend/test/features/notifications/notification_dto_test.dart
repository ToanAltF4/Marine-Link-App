import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/notifications/data/notification_dto.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';

void main() {
  test('notificationFromJson maps API payload with explicit related ids', () {
    final notification = notificationFromJson({
      'id': 'notification-001',
      'type': 'CHAT',
      'title': 'Tin nhắn mới',
      'body': 'Nhân viên đã phản hồi.',
      'relatedOrderId': null,
      'relatedProductId': null,
      'relatedChatRoomId': 'room-001',
      'isRead': false,
      'createdAt': '2026-05-28T08:30:00Z',
    });

    expect(notification.id, 'notification-001');
    expect(notification.type, NotificationType.chat);
    expect(notification.message, 'Nhân viên đã phản hồi.');
    expect(notification.relatedChatRoomId, 'room-001');
    expect(notification.relatedId, 'room-001');
    expect(notification.isRead, isFalse);
  });

  test(
    'notificationFromJson accepts legacy read field from backend response',
    () {
      final notification = notificationFromJson({
        'id': 'notification-002',
        'type': 'ORDER',
        'title': 'Đơn hàng',
        'body': 'Đơn đã giao.',
        'relatedOrderId': 'order-001',
        'read': true,
      });

      expect(notification.type, NotificationType.order);
      expect(notification.relatedOrderId, 'order-001');
      expect(notification.isRead, isTrue);
    },
  );
}
