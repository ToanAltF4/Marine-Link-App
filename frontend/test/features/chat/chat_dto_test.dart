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
}
