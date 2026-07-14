import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:marinelink/features/chat/presentation/screens/chat_screen.dart';
import 'package:marinelink/features/orders/domain/order.dart';
import 'package:marinelink/features/orders/domain/order_repository.dart';
import 'package:marinelink/features/orders/presentation/bloc/order_bloc.dart';
import 'package:marinelink/features/orders/presentation/screens/order_detail_screen.dart';

class _FakeOrderRepository implements OrderRepository {
  final OrderDetail order;

  const _FakeOrderRepository(this.order);

  @override
  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId) async =>
      ApiResponse(success: true, message: 'OK', data: order);

  @override
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) async => const ApiResponse(success: true, data: []);

  @override
  Future<ApiResponse<Order>> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    String? shippingAddressId,
    required String paymentMethod,
    String? note,
    List<OrderCreateItemInput>? items,
  }) async => ApiResponse(success: true, data: order);

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async => const ApiResponse(success: true);
}

class _FakeChatRepository implements ChatRepository {
  int orderRoomCalls = 0;

  @override
  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId) async {
    orderRoomCalls++;
    return ApiResponse(
      success: true,
      message: 'OK',
      data: ChatThread(
        roomId: 'order-room-001',
        isClosed: false,
        messages: [
          ChatMessage(
            id: 'seed-001',
            roomId: 'order-room-001',
            senderType: ChatSenderType.aiSample,
            content:
                'Khiếu nại đơn hàng ML-20260526-0001\nSản phẩm: Khô cá lóc\nTổng tiền: 7800000 VND',
            createdAt: DateTime.utc(2026, 6, 8, 8),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) async =>
      const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<ChatThread>> getMyRoom() async =>
      const ApiResponse(success: false, message: 'Unsupported');

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
  }) async => const ApiResponse(success: true, data: []);

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) async => ApiResponse(
    success: true,
    data: ChatMessage(
      id: 'sent-001',
      roomId: roomId,
      senderType: ChatSenderType.user,
      content: content,
      createdAt: DateTime.utc(2026, 6, 8, 8, 5),
    ),
  );

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

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('completed buyer order opens linked complaint chat room', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final chatRepository = _FakeChatRepository();
    sl.registerFactory<OrderBloc>(
      () => OrderBloc(orderRepository: _FakeOrderRepository(_completedOrder)),
    );
    sl.registerFactory<ChatCubit>(() => ChatCubit(repository: chatRepository));

    final router = GoRouter(
      initialLocation: '/orders/order-004',
      routes: [
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/chat/order/:orderId',
          builder: (context, state) =>
              ChatScreen(orderId: state.pathParameters['orderId']!),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('buyerComplaintChatButton')),
      280,
    );
    expect(
      find.byKey(const Key('buyerCompletedOrderActionsPanel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('buyerComplaintChatButton')));
    await tester.pumpAndSettle();

    expect(chatRepository.orderRoomCalls, 1);
    expect(find.byKey(const Key('chatScreen')), findsOneWidget);
    expect(find.textContaining('ML-20260526-0001'), findsOneWidget);
    expect(find.textContaining('Khô cá lóc'), findsOneWidget);
  });
}

final _completedOrder = OrderDetail(
  id: 'order-004',
  orderCode: 'ML-20260526-0001',
  status: OrderStatus.completed,
  totalAmount: 7800000,
  createdAt: DateTime.utc(2026, 5, 26, 6, 45),
  receiverName: 'Đại lý Hải Sản A',
  receiverPhone: '0912345678',
  shippingAddress: 'Cần Thơ',
  paymentMethod: PaymentMethod.bankTransfer,
  paymentStatus: 'PAID',
  subtotalAmount: 7800000,
  shippingFee: 0,
  discountAmount: 0,
  items: const [
    OrderItem(
      productId: 'prod-004',
      productNameSnapshot: 'Khô cá lóc',
      productUnitSnapshot: 'kg',
      unitPrice: 390000,
      quantity: 20,
    ),
  ],
  statusHistory: [
    OrderStatusHistory(
      fromStatus: null,
      toStatus: 'COMPLETED',
      note: 'Đại lý đã nhận hàng',
      createdAt: DateTime.utc(2026, 5, 27, 15, 20),
    ),
  ],
);
