import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/checkout/data/cart_sync_repository.dart';
import 'package:marinelink/features/checkout/data/order_checkout_repository.dart';
import 'package:marinelink/features/checkout/domain/checkout_repository.dart';
import 'package:marinelink/features/orders/domain/order.dart';
import 'package:marinelink/features/orders/domain/order_repository.dart';

void main() {
  test('syncs active local cart before creating remote order', () async {
    final cartSyncRepository = _FakeCartSyncRepository();
    final orderRepository = _FakeOrderRepository();
    final repository = OrderCheckoutRepository(
      orderRepository: orderRepository,
      cartSyncRepository: cartSyncRepository,
    );

    final response = await repository.createOrder(
      request: _request(),
      activeCart: _activeCart(),
    );

    expect(response.success, isTrue);
    expect(cartSyncRepository.syncCallCount, 1);
    expect(orderRepository.createOrderCallCount, 1);
    expect(orderRepository.lastItems, [
      const OrderCreateItemInput(
        productId: '550e8400-e29b-41d4-a716-446655440012',
        quantity: 2,
      ),
    ]);
    expect(
      cartSyncRepository.lastCart?.selectedItems.single.productId,
      '550e8400-e29b-41d4-a716-446655440012',
    );
  });

  test(
    'continues creating remote order when best-effort cart sync fails',
    () async {
      final cartSyncRepository = _FakeCartSyncRepository()
        ..response = const ApiResponse<void>(
          success: false,
          message: 'Giỏ hàng chưa đồng bộ',
        );
      final orderRepository = _FakeOrderRepository();
      final repository = OrderCheckoutRepository(
        orderRepository: orderRepository,
        cartSyncRepository: cartSyncRepository,
      );

      final response = await repository.createOrder(
        request: _request(),
        activeCart: _activeCart(),
      );

      expect(response.success, isTrue);
      expect(orderRepository.createOrderCallCount, 1);
    },
  );

  test(
    'returns backend order error message instead of throwing generic failure',
    () async {
      final orderRepository = _FakeOrderRepository()
        ..exception = const ApiException(
          message: 'Gio hang dang trong',
          type: ApiExceptionType.validation,
          statusCode: 422,
        );
      final repository = OrderCheckoutRepository(
        orderRepository: orderRepository,
        cartSyncRepository: _FakeCartSyncRepository(),
      );

      final response = await repository.createOrder(
        request: _request(),
        activeCart: _activeCart(),
      );

      expect(response.success, isFalse);
      expect(response.message, 'Gio hang dang trong');
    },
  );
}

CheckoutRequest _request() {
  return const CheckoutRequest(
    receiverName: 'Nguyen Van A',
    receiverPhone: '0912345678',
    shippingAddress: '123 Tran Hung Dao, Can Tho',
    paymentMethod: PaymentMethod.cod,
    note: 'Giao buoi sang',
  );
}

Cart _activeCart() {
  return const Cart(
    items: [
      CartItem(
        productId: '550e8400-e29b-41d4-a716-446655440012',
        productName: 'Muc kho loai 1',
        productImageUrl: '',
        unit: 'kg',
        quantity: 2,
        unitPrice: 90000,
        minOrderQuantity: 2,
        stockQuantity: 10,
      ),
    ],
  );
}

class _FakeCartSyncRepository implements CartSyncRepository {
  int syncCallCount = 0;
  Cart? lastCart;
  ApiResponse<void>? response;

  @override
  Future<ApiResponse<void>> syncCart(Cart cart) async {
    syncCallCount += 1;
    lastCart = cart;
    return response ?? const ApiResponse<void>(success: true);
  }
}

class _FakeOrderRepository implements OrderRepository {
  int createOrderCallCount = 0;
  List<OrderCreateItemInput>? lastItems;
  ApiException? exception;

  @override
  Future<ApiResponse<Order>> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    String? shippingAddressId,
    required String paymentMethod,
    String? note,
    List<OrderCreateItemInput>? items,
  }) async {
    createOrderCallCount += 1;
    lastItems = items;
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    return ApiResponse<Order>(
      success: true,
      data: Order(
        id: 'order-001',
        orderCode: 'ML-TEST-0001',
        status: OrderStatus.pending,
        totalAmount: 180000,
        createdAt: DateTime(2026, 6, 4),
      ),
    );
  }

  @override
  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) {
    throw UnimplementedError();
  }
}
