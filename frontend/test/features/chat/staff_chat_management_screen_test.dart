import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/staff_chat_cubit.dart';
import 'package:marinelink/features/chat/presentation/screens/staff_chat_management_screen.dart';

class _FakeRepo implements ChatRepository {
  Future<ApiResponse<List<StaffChatRoom>>> Function({
    StaffChatRoomFilter filter,
    String? query,
  })
  staffRoomsResponder;
  Future<ApiResponse<StaffChatComplaint>> Function({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  })
  complaintResponder;

  _FakeRepo({
    Future<ApiResponse<List<StaffChatRoom>>> Function({
      StaffChatRoomFilter filter,
      String? query,
    })?
    staffRoomsResponder,
    Future<ApiResponse<StaffChatComplaint>> Function({
      required String roomId,
      required String title,
      required String description,
      String? messageId,
    })?
    complaintResponder,
  }) : staffRoomsResponder =
           staffRoomsResponder ??
           (({filter = StaffChatRoomFilter.open, query}) async =>
               ApiResponse(success: true, message: 'OK', data: [_room])),
       complaintResponder =
           complaintResponder ??
           (({
             required roomId,
             required title,
             required description,
             messageId,
           }) async => ApiResponse(
             success: true,
             message: 'OK',
             data: StaffChatComplaint(
               id: 'complaint-001',
               roomId: roomId,
               title: title,
               description: description,
               status: 'OPEN',
             ),
           ));

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) async =>
      const ApiResponse(
        success: true,
        message: 'OK',
        data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
      );

  @override
  Future<ApiResponse<ChatThread>> getMyRoom() async => const ApiResponse(
    success: true,
    message: 'OK',
    data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
  );

  @override
  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId) async =>
      const ApiResponse(
        success: true,
        message: 'OK',
        data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
      );

  @override
  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  }) => staffRoomsResponder(filter: filter, query: query);

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) async => const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  }) async => ApiResponse(
    success: true,
    message: 'OK',
    data: _room.copyWith(isClosed: isClosed),
  );

  @override
  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) => complaintResponder(
    roomId: roomId,
    title: title,
    description: description,
    messageId: messageId,
  );
}

final _room = StaffChatRoom(
  roomId: 'room-001',
  customer: const StaffChatCustomer(
    id: 'user-001',
    fullName: 'Dai ly A',
    email: 'daily-a@demo.test',
    phone: '0901000001',
  ),
  assignedStaff: const StaffChatAssignee(id: 'staff-001', fullName: 'Staff'),
  isClosed: false,
  lastMessageAt: DateTime.utc(2026, 5, 28, 8, 30),
  messageCount: 2,
  context: const StaffChatContext(
    orderId: 'order-001',
    orderCode: 'ML-20260528-0001',
    orderStatus: 'PENDING',
    orderTotalAmount: 4200000,
    productId: 'product-001',
    productName: 'Muc kho loai 1',
  ),
  summary: 'Dai ly: Can ho tro don hang',
);

void _registerRepo(ChatRepository repo) {
  sl.registerFactory<StaffChatCubit>(() => StaffChatCubit(repository: repo));
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: StaffChatManagementScreen()));
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('shows loading while fetching staff rooms', (tester) async {
    final completer = Completer<ApiResponse<List<StaffChatRoom>>>();
    _registerRepo(
      _FakeRepo(
        staffRoomsResponder: ({filter = StaffChatRoomFilter.open, query}) =>
            completer.future,
      ),
    );

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('staffChatLoading')), findsOneWidget);

    completer.complete(
      ApiResponse(success: true, message: 'OK', data: [_room]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staffChatLoading')), findsNothing);
  });

  testWidgets('renders staff chat rooms and summary', (tester) async {
    _registerRepo(_FakeRepo());

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffChatSummaryCard')), findsOneWidget);
    expect(find.byKey(const Key('staffChatRoomCard_room-001')), findsOneWidget);
    expect(find.text('Dai ly A'), findsOneWidget);
    expect(find.text('Dai ly: Can ho tro don hang'), findsOneWidget);
    expect(find.byKey(const Key('staffChatContext_room-001')), findsOneWidget);
    expect(find.text('ML-20260528-0001'), findsOneWidget);
    expect(find.text('Muc kho loai 1'), findsOneWidget);
    expect(find.text('Chờ xác nhận'), findsOneWidget);
  });

  testWidgets('refreshes staff rooms periodically without loading flicker', (
    tester,
  ) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(
        staffRoomsResponder:
            ({filter = StaffChatRoomFilter.open, query}) async {
              calls++;
              return ApiResponse(success: true, message: 'OK', data: [_room]);
            },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staffChatLoading')), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(calls, greaterThanOrEqualTo(2));
    expect(find.byKey(const Key('staffChatLoading')), findsNothing);
    expect(find.byKey(const Key('staffChatRoomCard_room-001')), findsOneWidget);
  });

  testWidgets('shows empty state when no rooms match filter', (tester) async {
    _registerRepo(
      _FakeRepo(
        staffRoomsResponder:
            ({filter = StaffChatRoomFilter.open, query}) async =>
                const ApiResponse(success: true, message: 'OK', data: []),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffChatEmpty')), findsOneWidget);
  });

  testWidgets('shows error and retries', (tester) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(
        staffRoomsResponder:
            ({filter = StaffChatRoomFilter.open, query}) async {
              calls++;
              if (calls == 1) {
                return const ApiResponse(
                  success: false,
                  message: 'Network lost',
                );
              }
              return ApiResponse(success: true, message: 'OK', data: [_room]);
            },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffChatError')), findsOneWidget);

    await tester.tap(find.byKey(const Key('staffChatRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffChatError')), findsNothing);
    expect(find.byKey(const Key('staffChatRoomCard_room-001')), findsOneWidget);
  });

  testWidgets('filter chip reloads closed rooms', (tester) async {
    StaffChatRoomFilter? requestedFilter;
    _registerRepo(
      _FakeRepo(
        staffRoomsResponder:
            ({filter = StaffChatRoomFilter.open, query}) async {
              requestedFilter = filter;
              return ApiResponse(success: true, message: 'OK', data: [_room]);
            },
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('staffChatFilterClosed')));
    await tester.pumpAndSettle();

    expect(requestedFilter, StaffChatRoomFilter.closed);
  });

  testWidgets('creates complaint from room card', (tester) async {
    _registerRepo(_FakeRepo());

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('staffChatComplaintButton_room-001')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staffChatComplaintSheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('staffChatComplaintSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffChatComplaintSheet')), findsNothing);
    expect(find.textContaining('Khi\u1ebfu n\u1ea1i'), findsWidgets);
  });
}
