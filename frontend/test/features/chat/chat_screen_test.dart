import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:marinelink/features/chat/presentation/screens/chat_screen.dart';

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
  Future<ApiResponse<List<ChatRoomSummary>>> getMyRooms() async =>
      const ApiResponse(success: true, message: 'OK', data: []);

  @override
  Future<ApiResponse<ChatThread>> createRoom() async =>
      const ApiResponse(success: false, message: 'Unsupported');

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
      content: 'Need support for order',
      createdAt: DateTime.utc(2026, 5, 28, 8, 30),
    ),
    ChatMessage(
      id: 'message-002',
      roomId: 'room-001',
      senderType: ChatSenderType.staff,
      content: 'Order is being processed.',
      createdAt: DateTime.utc(2026, 5, 28, 8, 34),
    ),
  ],
);

void _registerRepo(ChatRepository repo) {
  sl.registerFactory<ChatCubit>(() => ChatCubit(repository: repo));
}

Alignment _bubbleAlignment(WidgetTester tester, String messageId) {
  final align = tester.widget<Align>(
    find.byKey(Key('chatMessageBubble_$messageId')),
  );
  return align.alignment as Alignment;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  bool staffMode = false,
  String? roomId = 'room-001',
  String? orderId,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(roomId: roomId, orderId: orderId, staffMode: staffMode),
    ),
  );
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('shows loading indicator while fetching chat history', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<ChatThread>>();
    _registerRepo(_FakeRepo(threadResponder: (_) => completer.future));

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('chatLoading')), findsOneWidget);

    completer.complete(
      ApiResponse(success: true, message: 'OK', data: _thread),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatLoading')), findsNothing);
  });

  testWidgets('buyer account: own (user) messages align right, staff left', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    );

    await _pumpScreen(tester, staffMode: false);
    await tester.pumpAndSettle();

    expect(_bubbleAlignment(tester, 'message-001'), Alignment.centerRight);
    expect(_bubbleAlignment(tester, 'message-002'), Alignment.centerLeft);
  });

  testWidgets('staff account: own (staff) messages align right, user left', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    );

    await _pumpScreen(tester, staffMode: true);
    await tester.pumpAndSettle();

    expect(_bubbleAlignment(tester, 'message-002'), Alignment.centerRight);
    expect(_bubbleAlignment(tester, 'message-001'), Alignment.centerLeft);
  });

  testWidgets('renders chat messages with sender labels and composer', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);
    expect(
      find.byKey(const Key('chatMessageBubble_message-001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chatMessageBubble_message-002')),
      findsOneWidget,
    );
    expect(find.text('\u0110\u1ea1i l\u00fd'), findsOneWidget);
    expect(find.text('Nh\u00e2n vi\u00ean'), findsOneWidget);
    expect(find.byKey(const Key('chatMessageTextField')), findsOneWidget);
  });

  testWidgets('shows empty state while keeping composer available', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async => const ApiResponse(
          success: true,
          message: 'OK',
          data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
        ),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatEmpty')), findsOneWidget);
    expect(find.byKey(const Key('chatMessageTextField')), findsOneWidget);
  });

  testWidgets(
    'refreshes open chat room periodically without clearing composer',
    (tester) async {
      var calls = 0;
      _registerRepo(
        _FakeRepo(
          threadResponder: (_) async {
            calls++;
            return ApiResponse(success: true, message: 'OK', data: _thread);
          },
        ),
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('chatMessageTextField')),
        'Dang nhap tin nhan',
      );
      // Fallback poll interval is 15s (realtime handles the fast path).
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();

      expect(calls, greaterThanOrEqualTo(2));
      expect(find.text('Dang nhap tin nhan'), findsOneWidget);
    },
  );

  testWidgets('opens completed order complaint room with order context', (
    tester,
  ) async {
    var orderRoomCalls = 0;
    final orderThread = ChatThread(
      roomId: 'order-room-001',
      isClosed: false,
      messages: [
        ChatMessage(
          id: 'message-order-001',
          roomId: 'order-room-001',
          senderType: ChatSenderType.aiSample,
          content: 'Khiếu nại đơn hàng ML-20260526-0001',
          createdAt: DateTime.utc(2026, 5, 28, 8, 30),
        ),
      ],
    );
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'not used'),
        orderRoomResponder: (orderId) async {
          orderRoomCalls++;
          expect(orderId, 'order-004');
          return ApiResponse(success: true, message: 'OK', data: orderThread);
        },
      ),
    );

    await _pumpScreen(tester, roomId: null, orderId: 'order-004');
    await tester.pumpAndSettle();

    expect(orderRoomCalls, 1);
    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);
    expect(find.text('Khiếu nại đơn hàng ML-20260526-0001'), findsOneWidget);
  });

  testWidgets('shows error with retry, then recovers', (tester) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async {
          calls++;
          if (calls == 1) {
            return const ApiResponse(success: false, message: 'Network lost');
          }
          return ApiResponse(success: true, message: 'OK', data: _thread);
        },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatError')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chatRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatError')), findsNothing);
    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);
  });

  testWidgets('keeps messages with offline fallback banner, then reloads', (
    tester,
  ) async {
    var calls = 0;
    late ChatCubit cubit;
    final repo = _FakeRepo(
      threadResponder: (_) async {
        calls++;
        if (calls == 2) {
          return const ApiResponse(
            success: false,
            message: 'M\u1ea5t k\u1ebft n\u1ed1i',
          );
        }
        return ApiResponse(success: true, message: 'OK', data: _thread);
      },
    );
    sl.registerFactory<ChatCubit>(() {
      cubit = ChatCubit(repository: repo);
      return cubit;
    });

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);

    await cubit.load('room-001');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);
    expect(find.byKey(const Key('chatOfflineFallbackBanner')), findsOneWidget);
    expect(find.byKey(const Key('chatOfflineRetryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chatOfflineRetryButton')));
    await tester.pumpAndSettle();

    expect(calls, 3);
    expect(find.byKey(const Key('chatOfflineFallbackBanner')), findsNothing);
    expect(find.byKey(const Key('chatMessagesList')), findsOneWidget);
  });

  testWidgets('sends a valid staff message and appends it to the list', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async {
              final message = ChatMessage(
                id: 'message-003',
                roomId: roomId,
                senderType: sendAsStaff
                    ? ChatSenderType.staff
                    : ChatSenderType.user,
                content: content,
                createdAt: DateTime.utc(2026, 5, 28, 8, 40),
              );
              return ApiResponse(
                success: true,
                message: 'Message sent',
                data: message,
              );
            },
      ),
    );

    await _pumpScreen(tester, staffMode: true);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chatMessageTextField')),
      'Checked order',
    );
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('chatMessageBubble_message-003')),
      findsOneWidget,
    );
    expect(find.text('Checked order'), findsOneWidget);
  });

  testWidgets('buyer chat tab creates room before sending first message', (
    tester,
  ) async {
    const emptyThread = ChatThread(
      roomId: 'room-001',
      isClosed: false,
      messages: [],
    );
    var myRoomCalls = 0;
    var sendCalls = 0;
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            const ApiResponse(success: false, message: 'not used'),
        myRoomResponder: () async {
          myRoomCalls++;
          return const ApiResponse(
            success: true,
            message: 'OK',
            data: emptyThread,
          );
        },
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async {
              sendCalls++;
              return ApiResponse(
                success: true,
                message: 'Message sent',
                data: ChatMessage(
                  id: 'message-003',
                  roomId: roomId,
                  senderType: ChatSenderType.user,
                  content: content,
                  createdAt: DateTime.utc(2026, 5, 28, 8, 40),
                ),
              );
            },
      ),
    );

    await _pumpScreen(tester, roomId: null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatEmpty')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chatMessageTextField')),
      'Tôi cần hỗ trợ đơn hàng.',
    );
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(myRoomCalls, 1);
    expect(sendCalls, 1);
    expect(
      find.byKey(const Key('chatMessageBubble_message-003')),
      findsOneWidget,
    );
    expect(find.text('Tôi cần hỗ trợ đơn hàng.'), findsOneWidget);
  });

  testWidgets('shows validation error for blank message', (tester) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chatMessageTextField')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pump();

    expect(find.byKey(const Key('chatInputError')), findsOneWidget);
    expect(find.byKey(const Key('chatRetrySendButton')), findsNothing);
  });

  testWidgets('keeps failed message and retries sending successfully', (
    tester,
  ) async {
    var sendCalls = 0;
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async {
              sendCalls++;
              if (sendCalls == 1) {
                return const ApiResponse(
                  success: false,
                  message: 'Mất kết nối khi gửi tin.',
                );
              }
              return ApiResponse(
                success: true,
                message: 'Message sent',
                data: ChatMessage(
                  id: 'message-003',
                  roomId: roomId,
                  senderType: ChatSenderType.user,
                  content: content,
                  createdAt: DateTime.utc(2026, 5, 28, 8, 45),
                ),
              );
            },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chatMessageTextField')),
      'Cần hỗ trợ lại',
    );
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatInputError')), findsOneWidget);
    expect(find.byKey(const Key('chatRetrySendButton')), findsOneWidget);
    expect(find.text('Cần hỗ trợ lại'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chatRetrySendButton')));
    await tester.pumpAndSettle();

    expect(sendCalls, 2);
    expect(find.byKey(const Key('chatInputError')), findsNothing);
    expect(find.byKey(const Key('chatRetrySendButton')), findsNothing);
    expect(
      find.byKey(const Key('chatMessageBubble_message-003')),
      findsOneWidget,
    );
  });

  testWidgets(
    'buyer sees "Doan chat moi" button instead of composer when room closed',
    (tester) async {
      _registerRepo(
        _FakeRepo(
          threadResponder: (_) async => ApiResponse(
            success: true,
            message: 'OK',
            data: _thread.copyWith(isClosed: true),
          ),
        ),
      );

      await _pumpScreen(tester, staffMode: false);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('chatNewConversationButton')),
        findsOneWidget,
      );
      expect(find.text('Đoạn chat mới'), findsOneWidget);
      // Composer is replaced: no text field / send button for the buyer.
      expect(find.byKey(const Key('chatMessageTextField')), findsNothing);
      expect(find.byKey(const Key('chatSendButton')), findsNothing);
    },
  );

  testWidgets('staff quick reply chip immediately sends the preset message', (
    tester,
  ) async {
    String? sentContent;
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async =>
            ApiResponse(success: true, message: 'OK', data: _thread),
        sendResponder:
            ({required roomId, required content, sendAsStaff = false}) async {
              sentContent = content;
              return ApiResponse(
                success: true,
                message: 'OK',
                data: ChatMessage(
                  id: 'message-quick',
                  roomId: roomId,
                  senderType: ChatSenderType.staff,
                  content: content,
                  createdAt: DateTime.utc(2026, 5, 28, 9, 0),
                ),
              );
            },
      ),
    );

    await _pumpScreen(tester, staffMode: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffQuickReplies')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quickReply0')));
    await tester.pumpAndSettle();

    expect(
      sentContent,
      'Anh/chị vui lòng để lại lời nhắn '
      'để được tư vấn thêm',
    );
    expect(
      find.byKey(const Key('chatMessageBubble_message-quick')),
      findsOneWidget,
    );
  });

  testWidgets('staff quick replies are hidden when room is closed', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async => ApiResponse(
          success: true,
          message: 'OK',
          data: _thread.copyWith(isClosed: true),
        ),
      ),
    );

    await _pumpScreen(tester, staffMode: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffQuickReplies')), findsNothing);
  });

  testWidgets('disables composer when room is closed', (tester) async {
    _registerRepo(
      _FakeRepo(
        threadResponder: (_) async => ApiResponse(
          success: true,
          message: 'OK',
          data: _thread.copyWith(isClosed: true),
        ),
      ),
    );

    await _pumpScreen(tester, staffMode: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chatClosedNotice')), findsOneWidget);
    final sendButton = tester.widget<FilledButton>(
      find.byKey(const Key('chatSendButton')),
    );
    expect(sendButton.onPressed, isNull);
  });
}
