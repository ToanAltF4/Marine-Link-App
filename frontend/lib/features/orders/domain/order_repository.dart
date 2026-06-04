import '../../../core/api/api_response.dart';
import 'order.dart';

class OrderCreateItemInput {
  final String productId;
  final int quantity;

  const OrderCreateItemInput({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderCreateItemInput &&
            runtimeType == other.runtimeType &&
            productId == other.productId &&
            quantity == other.quantity;
  }

  @override
  int get hashCode => Object.hash(productId, quantity);
}

/// Abstract order repository interface.
/// Mock implementation: OrderMockRepository (data/)
/// Remote implementation: OrderRemoteRepository (data/) — Sprint 5
abstract class OrderRepository {
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  });

  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId);

  Future<ApiResponse<Order>> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    String? shippingAddressId,
    required String paymentMethod,
    String? note,
    List<OrderCreateItemInput>? items,
  });

  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  });
}
