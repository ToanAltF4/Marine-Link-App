import '../../../core/api/api_response.dart';
import 'order.dart';

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
  });

  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  });
}
