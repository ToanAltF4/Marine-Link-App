import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/orders/data/order_remote_repository.dart';
import 'package:marinelink/features/orders/domain/order.dart';
import 'package:marinelink/features/orders/domain/order_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

final _order = Order(
  id: 'order-001',
  orderCode: 'ML-20260608-0001',
  status: OrderStatus.pending,
  totalAmount: 850000,
  createdAt: DateTime.utc(2026, 6, 8),
);

void main() {
  test('getOrders sends paging and status filters', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.get<List<Order>>(
        ApiEndpoints.orders,
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => ApiResponse(success: true, data: [_order]));

    final repository = OrderRemoteRepository(apiClient: apiClient);

    final response = await repository.getOrders(
      page: 1,
      size: 10,
      status: 'PENDING',
      fromDate: '2026-06-01',
      toDate: '2026-06-08',
    );

    expect(response.data, [_order]);
    final query =
        verify(
              () => apiClient.get<List<Order>>(
                ApiEndpoints.orders,
                queryParameters: captureAny(named: 'queryParameters'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(query, {
      'page': 1,
      'size': 10,
      'status': 'PENDING',
      'fromDate': '2026-06-01',
      'toDate': '2026-06-08',
    });
  });

  test(
    'createOrder posts checkout payload including shipping address id',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.post<Order>(
          ApiEndpoints.orders,
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => ApiResponse(success: true, data: _order));

      final repository = OrderRemoteRepository(apiClient: apiClient);

      final response = await repository.createOrder(
        receiverName: 'Nguyen Van A',
        receiverPhone: '0912345678',
        shippingAddress: 'Can Tho',
        shippingAddressId: ' address-001 ',
        paymentMethod: 'COD',
        note: ' giao sang ',
        items: const [
          OrderCreateItemInput(productId: 'product-001', quantity: 2),
        ],
      );

      expect(response.data, _order);
      final data =
          verify(
                () => apiClient.post<Order>(
                  ApiEndpoints.orders,
                  data: captureAny(named: 'data'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data['shippingAddressId'], 'address-001');
      expect(data['note'], 'giao sang');
      expect(data['items'], [
        {'productId': 'product-001', 'quantity': 2},
      ]);
    },
  );

  test(
    'updateOrderStatus sends admin status payload without blank note',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.put<void>(
          ApiEndpoints.orderStatus('order-001'),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => const ApiResponse<void>(success: true));

      final repository = OrderRemoteRepository(apiClient: apiClient);

      final response = await repository.updateOrderStatus(
        orderId: 'order-001',
        newStatus: 'CONFIRMED',
        note: '  ',
      );

      expect(response.success, isTrue);
      final data =
          verify(
                () => apiClient.put<void>(
                  ApiEndpoints.orderStatus('order-001'),
                  data: captureAny(named: 'data'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data, {'status': 'CONFIRMED'});
    },
  );
}
