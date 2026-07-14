import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/chat/data/chat_dto.dart';
import 'package:marinelink/features/chat/domain/chat.dart';

void main() {
  test('chatThreadFromJson parses a full payload with attachments', () {
    final thread = chatThreadFromJson({
      'roomId': 'room-001',
      'isClosed': false,
      'messages': [
        {
          'id': 'message-001',
          'roomId': 'room-001',
          'senderType': 'STAFF',
          'content': 'Order is being processed.',
          'createdAt': '2026-05-28T08:30:00Z',
          'attachments': [
            {
              'id': 'attachment-001',
              'storageBucket': 'chat-attachments',
              'storagePath': 'rooms/room-001/file.png',
              'fileName': 'file.png',
              'mimeType': 'image/png',
              'fileSizeBytes': 102400,
            },
          ],
        },
      ],
    });

    expect(thread.roomId, 'room-001');
    expect(thread.isClosed, false);
    expect(thread.messages.single.senderType, ChatSenderType.staff);
    expect(thread.messages.single.attachments.single.fileSizeBytes, 102400);
  });

  test('chatMessageFromJson tolerates missing fields', () {
    final message = chatMessageFromJson(<String, dynamic>{});

    expect(message.id, '');
    expect(message.roomId, '');
    expect(message.senderType, ChatSenderType.user);
    expect(message.content, '');
    expect(message.createdAt, isNull);
    expect(message.attachments, isEmpty);
  });

  test('chatThreadFromJson parses snake_case and string-like numbers', () {
    final thread = chatThreadFromJson({
      'id': 123,
      'closed': 'true',
      'messages': [
        {
          'public_id': 456,
          'room_id': 123,
          'sender_type': 'AI_SAMPLE',
          'content': 789,
          'created_at': '2026-05-28T08:30:00Z',
          'attachments': [
            {
              'public_id': 1,
              'storage_bucket': 'chat-attachments',
              'storage_path': 'rooms/file.pdf',
              'file_name': 'file.pdf',
              'mime_type': 'application/pdf',
              'file_size_bytes': '2048',
            },
          ],
        },
      ],
    });

    expect(thread.roomId, '123');
    expect(thread.isClosed, true);
    expect(thread.messages.single.id, '456');
    expect(thread.messages.single.content, '789');
    expect(thread.messages.single.senderType, ChatSenderType.aiSample);
    expect(thread.messages.single.attachments.single.fileSizeBytes, 2048);
  });

  test('staffChatRoomsFromJson parses room summary payload', () {
    final rooms = staffChatRoomsFromJson([
      {
        'roomId': 'room-001',
        'customer': {
          'id': 'user-001',
          'fullName': 'Dai ly A',
          'email': 'daily-a@demo.test',
          'phone': '0901000001',
        },
        'assignedStaff': {'id': 'staff-001', 'fullName': 'Staff Demo'},
        'isClosed': false,
        'lastMessageAt': '2026-05-28T08:30:00Z',
        'messageCount': '3',
        'lastMessage': {
          'id': 'message-001',
          'roomId': 'room-001',
          'senderType': 'USER',
          'content': 'Can ho tro',
        },
        'context': {
          'order_id': 'order-001',
          'order_code': 'ML-20260528-0001',
          'order_status': 'PENDING',
          'order_total_amount': '4200000',
          'product_id': 'product-001',
          'product_name': 'Muc kho loai 1',
          'product_image_url': 'https://example.com/product.png',
        },
        'summary': 'Dai ly: Can ho tro',
      },
    ]);

    expect(rooms, hasLength(1));
    expect(rooms.single.customer.fullName, 'Dai ly A');
    expect(rooms.single.assignedStaff!.fullName, 'Staff Demo');
    expect(rooms.single.messageCount, 3);
    expect(rooms.single.lastMessage!.senderType, ChatSenderType.user);
    expect(rooms.single.context!.orderCode, 'ML-20260528-0001');
    expect(rooms.single.context!.orderTotalAmount, 4200000);
    expect(rooms.single.context!.productName, 'Muc kho loai 1');
  });

  test('staffChatRoomFromJson tolerates missing nested fields', () {
    final room = staffChatRoomFromJson(<String, dynamic>{});

    expect(room.roomId, '');
    expect(room.customer.fullName, '');
    expect(room.assignedStaff, isNull);
    expect(room.messageCount, 0);
    expect(room.summary, '');
  });

  test('staffChatComplaintFromJson parses complaint payload', () {
    final complaint = staffChatComplaintFromJson({
      'id': 'complaint-001',
      'room_id': 'room-001',
      'message_id': 'message-001',
      'title': 'Giao thieu hang',
      'description': 'Khach bao giao thieu hang',
      'status': 'OPEN',
      'created_at': '2026-05-28T08:40:00Z',
    });

    expect(complaint.id, 'complaint-001');
    expect(complaint.roomId, 'room-001');
    expect(complaint.messageId, 'message-001');
    expect(complaint.status, 'OPEN');
    expect(complaint.createdAt, isNotNull);
  });
}
