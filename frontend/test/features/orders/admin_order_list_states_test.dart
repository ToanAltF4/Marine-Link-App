import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/orders/domain/order.dart';
import 'package:marinelink/features/orders/domain/order_repository.dart';
import 'package:marinelink/features/orders/presentation/bloc/order_bloc.dart';
import 'package:marinelink/features/orders/presentation/screens/order_list_screen.dart';

class _FakeOrderRepository implements OrderRepository {
  final Future<ApiResponse<List<Order>>> Function({String? status})
  listResponder;

  _FakeOrderRepository({required this.listResponder});

  @override
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) => listResponder(status: status);

  @override
  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId) async =>
      const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<Order>> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    String? shippingAddressId,
    required String paymentMethod,
    String? note,
    List<OrderCreateItemInput>? items,
  }) async => const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async => const ApiResponse(success: false, message: 'Unsupported');
}

final _adminOrder = Order(
  id: 'order-admin-001',
  orderCode: 'ML-ADMIN-001',
  status: OrderStatus.pending,
  totalAmount: 1200000,
  createdAt: DateTime.utc(2026, 6, 8, 8),
);

void _registerOrderBloc(OrderRepository repository) {
  sl.registerFactory<OrderBloc>(() => OrderBloc(orderRepository: repository));
}

Future<void> _pumpAdminOrders(WidgetTester tester, {bool settle = true}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    const MaterialApp(home: OrderListScreen(adminMode: true)),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  testWidgets('admin order list exposes loading state at phone width', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<List<Order>>>();
    _registerOrderBloc(
      _FakeOrderRepository(listResponder: ({status}) => completer.future),
    );

    await _pumpAdminOrders(tester, settle: false);
    await tester.pump();

    expect(find.byKey(const Key('adminOrdersLoading')), findsOneWidget);

    completer.complete(
      ApiResponse(success: true, message: 'OK', data: [_adminOrder]),
    );
  });

  testWidgets('admin order list shows error with retry then empty state', (
    tester,
  ) async {
    var calls = 0;
    _registerOrderBloc(
      _FakeOrderRepository(
        listResponder: ({status}) async {
          calls++;
          if (calls == 1) {
            return const ApiResponse(
              success: false,
              message: 'M\u1ea5t k\u1ebft n\u1ed1i',
            );
          }
          return const ApiResponse(success: true, message: 'OK', data: []);
        },
      ),
    );

    await _pumpAdminOrders(tester);

    expect(find.byKey(const Key('adminOrdersError')), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminOrdersError')), findsNothing);
    expect(find.byKey(const Key('adminOrdersEmpty')), findsOneWidget);
  });

  testWidgets('admin order list shows filtered empty state', (tester) async {
    _registerOrderBloc(
      _FakeOrderRepository(
        listResponder: ({status}) async =>
            ApiResponse(success: true, message: 'OK', data: [_adminOrder]),
      ),
    );

    await _pumpAdminOrders(tester);

    await tester.enterText(find.byType(TextField), 'NO-MATCH');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminOrdersFilteredEmpty')), findsOneWidget);
  });
}
