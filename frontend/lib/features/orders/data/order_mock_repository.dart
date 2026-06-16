import '../domain/order.dart';
import '../domain/order_repository.dart';
import '../../../core/api/api_response.dart';

/// Mock OrderRepository for Sprint 1/2.
/// Returns hard-coded demo orders for testing the order list and detail screens.
/// Replace with OrderRemoteRepository in Sprint 5 via DI — no UI changes needed.
class OrderMockRepository implements OrderRepository {
  static final List<OrderDetail> _orders = [
    OrderDetail(
      id: 'order-001',
      orderCode: 'ML-20260528-0001',
      status: OrderStatus.pending,
      totalAmount: 4200000,
      createdAt: DateTime.parse('2026-05-28T08:30:00Z'),
      receiverName: 'Đại lý Nguyễn Văn A',
      receiverPhone: '0912345678',
      shippingAddress: 'Cần Thơ',
      paymentMethod: PaymentMethod.cod,
      paymentStatus: 'UNPAID',
      subtotalAmount: 4200000,
      shippingFee: 0,
      discountAmount: 0,
      note: 'Giao buổi sáng',
      items: const [
        OrderItem(
          productId: 'prod-001',
          productNameSnapshot: 'Mực khô loại 1',
          productUnitSnapshot: 'kg',
          unitPrice: 420000,
          quantity: 10,
        ),
      ],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: DateTime.parse('2026-05-28T08:30:00Z'),
        ),
      ],
    ),
    OrderDetail(
      id: 'order-002',
      orderCode: 'ML-20260529-0001',
      status: OrderStatus.confirmed,
      totalAmount: 3250000,
      createdAt: DateTime.parse('2026-05-29T09:15:00Z'),
      receiverName: 'Đại lý Nguyễn Văn A',
      receiverPhone: '0912345678',
      shippingAddress: 'Cần Thơ',
      paymentMethod: PaymentMethod.bankTransfer,
      paymentStatus: 'UNPAID',
      subtotalAmount: 3250000,
      shippingFee: 0,
      discountAmount: 0,
      items: const [
        OrderItem(
          productId: 'prod-002',
          productNameSnapshot: 'Tôm khô size lớn',
          productUnitSnapshot: 'kg',
          unitPrice: 650000,
          quantity: 5,
        ),
      ],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: DateTime.parse('2026-05-29T09:15:00Z'),
        ),
        OrderStatusHistory(
          fromStatus: 'PENDING',
          toStatus: 'CONFIRMED',
          note: 'Đã xác nhận hàng',
          createdAt: DateTime.parse('2026-05-29T10:00:00Z'),
        ),
      ],
    ),
    OrderDetail(
      id: 'order-003',
      orderCode: 'ML-20260530-0001',
      status: OrderStatus.shipping,
      totalAmount: 950000,
      createdAt: DateTime.parse('2026-05-30T07:00:00Z'),
      receiverName: 'Đại lý Nguyễn Văn A',
      receiverPhone: '0912345678',
      shippingAddress: 'Cần Thơ',
      paymentMethod: PaymentMethod.cod,
      paymentStatus: 'UNPAID',
      subtotalAmount: 950000,
      shippingFee: 0,
      discountAmount: 0,
      items: const [
        OrderItem(
          productId: 'prod-003',
          productNameSnapshot: 'Cá khô dứa',
          productUnitSnapshot: 'kg',
          unitPrice: 320000,
          quantity: 3,
        ),
      ],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: DateTime.parse('2026-05-30T07:00:00Z'),
        ),
        OrderStatusHistory(
          fromStatus: 'PENDING',
          toStatus: 'CONFIRMED',
          note: 'Đã xác nhận',
          createdAt: DateTime.parse('2026-05-30T07:30:00Z'),
        ),
        OrderStatusHistory(
          fromStatus: 'CONFIRMED',
          toStatus: 'SHIPPING',
          note: 'Đã bàn giao đơn vị vận chuyển',
          createdAt: DateTime.parse('2026-05-30T08:00:00Z'),
        ),
      ],
    ),
    OrderDetail(
      id: 'order-004',
      orderCode: 'ML-20260526-0001',
      status: OrderStatus.completed,
      totalAmount: 7800000,
      createdAt: DateTime.parse('2026-05-26T06:45:00Z'),
      receiverName: 'Đại lý Nguyễn Văn A',
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
          productImageUrl: 'https://example.com/kho-ca-loc.png',
          unitPrice: 390000,
          quantity: 20,
        ),
      ],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: DateTime.parse('2026-05-26T06:45:00Z'),
        ),
        OrderStatusHistory(
          fromStatus: 'SHIPPING',
          toStatus: 'COMPLETED',
          note: 'Đại lý đã nhận hàng',
          createdAt: DateTime.parse('2026-05-27T15:20:00Z'),
        ),
      ],
    ),
    OrderDetail(
      id: 'order-005',
      orderCode: 'ML-20260525-0001',
      status: OrderStatus.cancelled,
      totalAmount: 1500000,
      createdAt: DateTime.parse('2026-05-25T10:10:00Z'),
      receiverName: 'Đại lý Nguyễn Văn A',
      receiverPhone: '0912345678',
      shippingAddress: 'Cần Thơ',
      paymentMethod: PaymentMethod.cod,
      paymentStatus: 'UNPAID',
      subtotalAmount: 1500000,
      shippingFee: 0,
      discountAmount: 0,
      note: 'Đại lý đổi kế hoạch nhập hàng',
      items: const [
        OrderItem(
          productId: 'prod-005',
          productNameSnapshot: 'Mực một nắng',
          productUnitSnapshot: 'kg',
          unitPrice: 500000,
          quantity: 3,
        ),
      ],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: DateTime.parse('2026-05-25T10:10:00Z'),
        ),
        OrderStatusHistory(
          fromStatus: 'PENDING',
          toStatus: 'CANCELLED',
          note: 'Đại lý yêu cầu huỷ đơn',
          createdAt: DateTime.parse('2026-05-25T11:00:00Z'),
        ),
      ],
    ),
  ];

  @override
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 0,
    int size = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    var filtered = List<OrderDetail>.from(_orders);

    if (status != null) {
      final s = OrderStatus.fromString(status);
      filtered = filtered.where((o) => o.status == s).toList();
    }

    final orders = filtered.cast<Order>();
    final total = orders.length;
    final start = page * size;
    final end = (start + size).clamp(0, total);
    final paged = start < total ? orders.sublist(start, end) : <Order>[];

    return ApiResponse<List<Order>>(
      success: true,
      message: 'OK',
      data: paged,
      pagination: ApiPagination(
        page: page,
        size: size,
        totalElements: total,
        totalPages: (total / size).ceil(),
      ),
    );
  }

  @override
  Future<ApiResponse<OrderDetail>> getOrderDetail(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final order = _orders.where((o) => o.id == orderId).firstOrNull;
    if (order == null) {
      return const ApiResponse<OrderDetail>(
        success: false,
        message: 'Không tìm thấy đơn hàng',
        data: null,
      );
    }

    return ApiResponse<OrderDetail>(success: true, message: 'OK', data: order);
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final code =
        'ML-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(_orders.length + 1).toString().padLeft(4, '0')}';

    final parsedPaymentMethod = PaymentMethod.fromString(paymentMethod);
    final newOrder = OrderDetail(
      id: 'order-mock-${_orders.length + 1}',
      orderCode: code,
      status: OrderStatus.pending,
      totalAmount: 0, // will be computed by server in real impl
      createdAt: now,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      shippingAddress: shippingAddress,
      paymentMethod: parsedPaymentMethod,
      paymentStatus:
          parsedPaymentMethod == PaymentMethod.bankTransfer ||
              parsedPaymentMethod == PaymentMethod.vnpay
          ? 'PENDING'
          : 'UNPAID',
      subtotalAmount: 0,
      shippingFee: 0,
      discountAmount: 0,
      note: note,
      items: const [],
      statusHistory: [
        OrderStatusHistory(
          fromStatus: null,
          toStatus: 'PENDING',
          note: 'Order created',
          createdAt: now,
        ),
      ],
    );

    _orders.add(newOrder);
    return ApiResponse<Order>(
      success: true,
      message: 'Order created',
      data: newOrder,
    );
  }

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) {
      return const ApiResponse<void>(
        success: false,
        message: 'Không tìm thấy đơn hàng',
      );
    }

    final order = _orders[index];
    final targetStatus = OrderStatus.fromString(newStatus);

    if (!order.status.allowedTransitions.contains(targetStatus)) {
      return ApiResponse<void>(
        success: false,
        message:
            'Không thể chuyển trạng thái từ ${order.status.displayLabel} sang ${targetStatus.displayLabel}',
      );
    }
    if (targetStatus == OrderStatus.confirmed && order.isWaitingForPayment) {
      return const ApiResponse<void>(
        success: false,
        message: 'Đơn hàng chưa thanh toán',
      );
    }

    final trimmedNote = note?.trim();
    final updatedOrder = OrderDetail(
      id: order.id,
      orderCode: order.orderCode,
      status: targetStatus,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt,
      receiverName: order.receiverName,
      receiverPhone: order.receiverPhone,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      subtotalAmount: order.subtotalAmount,
      shippingFee: order.shippingFee,
      discountAmount: order.discountAmount,
      note: order.note,
      items: order.items,
      statusHistory: [
        ...order.statusHistory,
        OrderStatusHistory(
          fromStatus: order.status.apiValue,
          toStatus: targetStatus.apiValue,
          note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
          createdAt: DateTime.now(),
        ),
      ],
    );

    _orders[index] = updatedOrder;

    return const ApiResponse<void>(
      success: true,
      message: 'Order status updated',
    );
  }
}
