import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/chat_cubit.dart';

class _FakeRepo implements ChatRepository {
  final Future<ApiResponse<ChatThread>> Function(String roomId) threadResponder;
  final Future<ApiResponse<ChatMessage>> Function({
    required String roomId,
    required String content,
    bool sendAsStaff,
  })
  sendResponder;

  _FakeRepo({
    required this.threadResponder,
    Future<ApiResponse<ChatMessage>> Function({
      required String roomId,
      required String content,
      bool sendAsStaff,
    })?
    sendResponder,
  }) : sendResponder =
           sendResponder ??
           (({required roomId, required content, sendAsStaff = false}) async =>
               const ApiResponse(success: false, message: 'Cannot send'));

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) =>
      threadResponder(roomId);

  @override
  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  }) async => const ApiResponse(success: true, message: 'OK', data: []);

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) =>
      sendResponder(roomId: roomId, content: content, sendAsStaff: sendAsStaff);

  @override
  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  }) async => const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) async => const ApiResponse(success: false, message: 'Unsupported');
}

final _thread = ChatThread(
  roomId: 'room-001',
  isClosed: false,
  messages: [
    ChatMessage(
      id: 'message-001',
      roomId: 'room-001',
      senderType: ChatSenderType.user,
      content: 'Hello',
      createdAt: DateTime.utc(2026, 5, 28, 8, 30),
    ),
  ],
);

final _sentMessage = ChatMessage(
  id: 'message-002',
  roomId: 'room-001',
  senderType: ChatSenderType.staff,
  content: 'I will check now.',
  createdAt: DateTime.utc(2026, 5, 28, 8, 35),
);

void main() {
  blocTest<ChatCubit, ChatState>(
    'emits [loading, success] when repository returns messages',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.messages.length, 'message count', 1),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'emits [loading, empty] when repository returns no messages',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async => const ApiResponse(
          success: true,
          message: 'OK',
          data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
        ),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.empty,
      ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'emits [loading, failure] when repository reports failure',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'Network lost'),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.failure)
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            'Network lost',
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'emits [loading, failure] when repository throws',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async => throw Exception('boom'),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.failure,
      ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage appends the sent message',
    seed: () => ChatState(
      status: ChatStatus.success,
      roomId: 'room-001',
      thread: _thread,
    ),
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async =>
                ApiResponse(
                  success: true,
                  message: 'Message sent',
                  data: _sentMessage,
                ),
      ),
    ),
    act: (cubit) => cubit.sendMessage('I will check now.', sendAsStaff: true),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.sending, 'sending', false)
          .having((state) => state.messages.length, 'message count', 2)
          .having(
            (state) => state.messages.last.senderType,
            'sender',
            ChatSenderType.staff,
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage surfaces repository failure',
    seed: () => ChatState(
      status: ChatStatus.success,
      roomId: 'room-001',
      thread: _thread,
    ),
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async =>
                const ApiResponse(success: false, message: 'Room closed'),
      ),
    ),
    act: (cubit) => cubit.sendMessage('New message'),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.sending, 'sending', false)
          .having(
            (state) => state.sendErrorMessage,
            'sendErrorMessage',
            'Room closed',
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage rejects blank input on client side',
    seed: () => ChatState(
      status: ChatStatus.success,
      roomId: 'room-001',
      thread: _thread,
    ),
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    ),
    act: (cubit) => cubit.sendMessage('   '),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.sendErrorMessage,
        'sendErrorMessage',
        isNotEmpty,
      ),
    ],
  );
}
