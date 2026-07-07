import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/data/chat_realtime_service.dart';
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

  final Future<ApiResponse<ChatThread>> Function()? myRoomResponder;
  final Future<ApiResponse<ChatThread>> Function(String orderId)?
  orderRoomResponder;

  _FakeRepo({
    required this.threadResponder,
    this.myRoomResponder,
    this.orderRoomResponder,
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
  Future<ApiResponse<ChatThread>> getMyRoom() =>
      (myRoomResponder ?? () => threadResponder('my-room'))();

  @override
  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId) =>
      (orderRoomResponder ?? (_) => threadResponder('order-room'))(orderId);

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

class _FakeRealtime implements ChatRealtimeService {
  String? subscribedRoomId;
  void Function(ChatMessage message)? _onMessage;
  int cancelled = 0;

  @override
  ChatRealtimeSubscription subscribeToRoom(
    String roomId,
    void Function(ChatMessage message) onMessage,
  ) {
    subscribedRoomId = roomId;
    _onMessage = onMessage;
    return _FakeSub(this);
  }

  @override
  Future<void> dispose() async {}

  void emit(ChatMessage message) => _onMessage?.call(message);
}

class _FakeSub implements ChatRealtimeSubscription {
  final _FakeRealtime owner;
  _FakeSub(this.owner);
  @override
  void cancel() => owner.cancelled++;
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

const _emptyThread = ChatThread(
  roomId: 'room-001',
  isClosed: false,
  messages: [],
);

final _sentBuyerMessage = ChatMessage(
  id: 'message-003',
  roomId: 'room-001',
  senderType: ChatSenderType.user,
  content: 'Tôi cần hỗ trợ đơn hàng.',
  createdAt: DateTime.utc(2026, 5, 28, 8, 40),
);

void main() {
  test('subscribes to the loaded room and appends realtime messages', () async {
    final realtime = _FakeRealtime();
    final cubit = ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
      realtime: realtime,
    );

    await cubit.load('room-001');
    expect(realtime.subscribedRoomId, 'room-001');
    expect(cubit.state.thread!.messages.length, 1);

    // A message pushed over the socket is appended instantly.
    realtime.emit(_sentMessage);
    expect(cubit.state.thread!.messages.length, 2);
    expect(cubit.state.thread!.messages.last.id, 'message-002');

    // The same message echoed again is de-duplicated by id.
    realtime.emit(_sentMessage);
    expect(cubit.state.thread!.messages.length, 2);

    await cubit.close();
    expect(realtime.cancelled, greaterThanOrEqualTo(1));
  });

  blocTest<ChatCubit, ChatState>(
    'loadMyRoom resolves the user support room (buyer tab)',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'should not be used'),
        myRoomResponder: () async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    ),
    act: (cubit) => cubit.loadMyRoom(),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.roomId, 'roomId', 'room-001')
          .having((state) => state.messages.length, 'message count', 1),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'loadOrderRoom creates the completed order complaint room',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'should not be used'),
        orderRoomResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    ),
    act: (cubit) => cubit.loadOrderRoom('order-001'),
    expect: () => [
      isA<ChatState>().having(
        (state) => state.status,
        'status',
        ChatStatus.loading,
      ),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.roomId, 'roomId', 'room-001')
          .having((state) => state.messages.length, 'message count', 1),
    ],
  );

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
    'keeps cached thread as offline fallback when reload fails',
    seed: () => ChatState(
      status: ChatStatus.success,
      roomId: 'room-001',
      thread: _thread,
    ),
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async => const ApiResponse(
          success: false,
          message: 'M\u1ea5t k\u1ebft n\u1ed1i',
        ),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.offlineFallback, 'offlineFallback', true)
          .having((state) => state.messages.length, 'message count', 1)
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            contains('d\u1eef li\u1ec7u g\u1ea7n nh\u1ea5t'),
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
    'uses ApiException message for cached offline fallback',
    seed: () => ChatState(
      status: ChatStatus.success,
      roomId: 'room-001',
      thread: _thread,
    ),
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async => throw const ApiException(
          message:
              'K\u1ebft n\u1ed1i qu\u00e1 ch\u1eadm. Vui l\u00f2ng th\u1eed l\u1ea1i.',
          type: ApiExceptionType.network,
        ),
      ),
    ),
    act: (cubit) => cubit.load('room-001'),
    expect: () => [
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.offlineFallback, 'offlineFallback', true)
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            contains('K\u1ebft n\u1ed1i qu\u00e1 ch\u1eadm'),
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
          .having((state) => state.canRetrySend, 'canRetrySend', false)
          .having((state) => state.messages.length, 'message count', 2)
          .having(
            (state) => state.messages.last.senderType,
            'sender',
            ChatSenderType.staff,
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage creates buyer support room first when roomId is missing',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'not used'),
        myRoomResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: _emptyThread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async =>
                ApiResponse(
                  success: true,
                  message: 'Message sent',
                  data: _sentBuyerMessage,
                ),
      ),
    ),
    act: (cubit) => cubit.sendMessage('Tôi cần hỗ trợ đơn hàng.'),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.empty)
          .having((state) => state.roomId, 'roomId', 'room-001')
          .having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.status, 'status', ChatStatus.success)
          .having((state) => state.sending, 'sending', false)
          .having((state) => state.canRetrySend, 'canRetrySend', false)
          .having((state) => state.messages.length, 'message count', 1)
          .having(
            (state) => state.messages.last.content,
            'content',
            'Tôi cần hỗ trợ đơn hàng.',
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage keeps retry enabled when buyer support room cannot be created',
    build: () => ChatCubit(
      repository: _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'not used'),
        myRoomResponder: () async => const ApiResponse(
          success: false,
          message: 'Không chuẩn bị được phòng chat.',
        ),
      ),
    ),
    act: (cubit) => cubit.sendMessage('Tôi cần hỗ trợ đơn hàng.'),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.sending, 'sending', false)
          .having((state) => state.canRetrySend, 'canRetrySend', true)
          .having(
            (state) => state.sendErrorMessage,
            'sendErrorMessage',
            'Không chuẩn bị được phòng chat.',
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
          .having((state) => state.canRetrySend, 'canRetrySend', true)
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
      isA<ChatState>()
          .having(
            (state) => state.sendErrorMessage,
            'sendErrorMessage',
            isNotEmpty,
          )
          .having((state) => state.canRetrySend, 'canRetrySend', false),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage surfaces thrown error as retryable',
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
            ({required roomId, required content, sendAsStaff = false}) {
              throw Exception('timeout');
            },
      ),
    ),
    act: (cubit) => cubit.sendMessage('New message'),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.sending, 'sending', false)
          .having((state) => state.canRetrySend, 'canRetrySend', true)
          .having(
            (state) => state.sendErrorMessage,
            'sendErrorMessage',
            isNotEmpty,
          ),
    ],
  );

  blocTest<ChatCubit, ChatState>(
    'sendMessage uses ApiException message as retryable remote error',
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
            ({required roomId, required content, sendAsStaff = false}) async {
              throw const ApiException(
                message:
                    'K\u1ebft n\u1ed1i qu\u00e1 ch\u1eadm. Vui l\u00f2ng th\u1eed l\u1ea1i.',
                type: ApiExceptionType.network,
              );
            },
      ),
    ),
    act: (cubit) => cubit.sendMessage('New message'),
    expect: () => [
      isA<ChatState>().having((state) => state.sending, 'sending', true),
      isA<ChatState>()
          .having((state) => state.sending, 'sending', false)
          .having((state) => state.canRetrySend, 'canRetrySend', true)
          .having(
            (state) => state.sendErrorMessage,
            'sendErrorMessage',
            contains('K\u1ebft n\u1ed1i qu\u00e1 ch\u1eadm'),
          ),
    ],
  );
}
