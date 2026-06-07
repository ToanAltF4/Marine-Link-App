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

  test('getStaffRooms filters open and closed rooms', () async {
    final repository = ChatMockRepository();

    final openResponse = await repository.getStaffRooms();
    final closedResponse = await repository.getStaffRooms(
      filter: StaffChatRoomFilter.closed,
    );

    expect(openResponse.success, true);
    expect(openResponse.data, isNotEmpty);
    expect(openResponse.data!.every((room) => !room.isClosed), true);
    expect(closedResponse.data, isNotEmpty);
    expect(closedResponse.data!.every((room) => room.isClosed), true);
  });

  test('setRoomClosed updates room and thread status', () async {
    final repository = ChatMockRepository();

    final response = await repository.setRoomClosed(
      roomId: ChatMockRepository.defaultRoomId,
      isClosed: true,
    );
    final threadResponse = await repository.getThread(
      ChatMockRepository.defaultRoomId,
    );

    expect(response.success, true);
    expect(response.data!.isClosed, true);
    expect(threadResponse.data!.isClosed, true);
  });

  test('createComplaint creates complaint from room', () async {
    final repository = ChatMockRepository();

    final response = await repository.createComplaint(
      roomId: ChatMockRepository.defaultRoomId,
      title: 'Giao thieu hang',
      description: 'Khach bao giao thieu hang',
    );

    expect(response.success, true);
    expect(response.data!.status, 'OPEN');
    expect(response.data!.roomId, ChatMockRepository.defaultRoomId);
  });
}
