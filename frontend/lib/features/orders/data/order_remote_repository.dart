import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/order.dart';
import '../domain/order_repository.dart';
import 'order_dto.dart';

class OrderRemoteRepository implements OrderRepository {
  final ApiClient apiClient;

  const OrderRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) {
    return apiClient.get<List<Order>>(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null && status.isNotEmpty) 'status': status,
        if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      },
      fromJson: orderListFromJson,
    );
  }

  @override
  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId) {
    return apiClient.get<OrderDetail>(
      ApiEndpoints.orderDetail(orderId),
      fromJson: orderDetailFromJson,
    );
  }

  @override
  Future<ApiResponse<Order>> createOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    String? shippingAddressId,
    required String paymentMethod,
    String? note,
    List<OrderCreateItemInput>? items,
  }) {
    return apiClient.post<Order>(
      ApiEndpoints.orders,
      data: {
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (items != null && items.isNotEmpty)
          'items': items.map((item) => item.toJson()).toList(),
      },
      fromJson: orderSummaryFromJson,
    );
  }

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) {
    return apiClient.put<void>(
      ApiEndpoints.orderStatus(orderId),
      data: {
        'status': newStatus,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fromJson: (_) {},
    );
  }
}
