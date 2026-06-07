import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/chat/data/chat_mock_repository.dart';
import 'package:marinelink/features/chat/domain/chat.dart';

void main() {
  test('getThread returns seeded messages', () async {
    final repository = ChatMockRepository();

    final response = await repository.getThread(
      ChatMockRepository.defaultRoomId,
    );

    expect(response.success, true);
    expect(response.data, isNotNull);
    expect(response.data!.messages, isNotEmpty);
    expect(
      response.data!.messages.map((message) => message.senderType),
      contains(ChatSenderType.staff),
    );
  });

  test('getThread returns empty room', () async {
    final repository = ChatMockRepository();

    final response = await repository.getThread(ChatMockRepository.emptyRoomId);

    expect(response.success, true);
    expect(response.data!.messages, isEmpty);
  });

  test('sendMessage appends user message to in-memory thread', () async {
    final repository = ChatMockRepository();

    final sendResponse = await repository.sendMessage(
      roomId: ChatMockRepository.defaultRoomId,
      content: '  Need support for order  ',
    );
    final listResponse = await repository.getThread(
      ChatMockRepository.defaultRoomId,
    );

    expect(sendResponse.success, true);
    expect(sendResponse.data!.senderType, ChatSenderType.user);
    expect(sendResponse.data!.content, 'Need support for order');
    expect(listResponse.data!.messages.last.content, 'Need support for order');
  });

  test('sendMessage can append staff message for staff view', () async {
    final repository = ChatMockRepository();

    final response = await repository.sendMessage(
      roomId: ChatMockRepository.defaultRoomId,
      content: 'Staff reply',
      sendAsStaff: true,
    );

    expect(response.success, true);
    expect(response.data!.senderType, ChatSenderType.staff);
  });

  test('sendMessage rejects blank content', () async {
    final repository = ChatMockRepository();

    final response = await repository.sendMessage(
      roomId: ChatMockRepository.defaultRoomId,
      content: '   ',
    );

    expect(response.success, false);
    expect(response.message, isNotEmpty);
  });
}
