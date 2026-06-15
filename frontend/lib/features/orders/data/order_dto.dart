import '../domain/order.dart';

class OrderDto {
  final String id;
  final String orderCode;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final DateTime createdAt;

  const OrderDto({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentStatus: json['paymentStatus'] as String? ?? 'UNPAID',
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Order toDomain() {
    return Order(
      id: id,
      orderCode: orderCode,
      status: OrderStatus.fromString(status),
      paymentMethod: PaymentMethod.fromString(paymentMethod),
      paymentStatus: paymentStatus,
      totalAmount: totalAmount,
      createdAt: createdAt,
    );
  }
}

class OrderItemDto {
  final String productId;
  final String productNameSnapshot;
  final String productUnitSnapshot;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;

  const OrderItemDto({
    required this.productId,
    required this.productNameSnapshot,
    required this.productUnitSnapshot,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'] as String,
      productNameSnapshot: json['productNameSnapshot'] as String,
      productUnitSnapshot: json['productUnitSnapshot'] as String? ?? 'kg',
      productImageUrl: json['productImageUrl'] as String?,
      unitPrice: (json['unitPrice'] as num? ?? 0).toDouble(),
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  OrderItem toDomain() {
    return OrderItem(
      productId: productId,
      productNameSnapshot: productNameSnapshot,
      productUnitSnapshot: productUnitSnapshot,
      productImageUrl: productImageUrl,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}

class OrderStatusHistoryDto {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;

  const OrderStatusHistoryDto({
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistoryDto.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryDto(
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String? ?? 'PENDING',
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  OrderStatusHistory toDomain() {
    return OrderStatusHistory(
      fromStatus: fromStatus,
      toStatus: toStatus,
      note: note,
      createdAt: createdAt,
    );
  }
}

class OrderDetailDto extends OrderDto {
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final double subtotalAmount;
  final double shippingFee;
  final double discountAmount;
  final String? note;
  final List<OrderItemDto> items;
  final List<OrderStatusHistoryDto> statusHistory;

  const OrderDetailDto({
    required super.id,
    required super.orderCode,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.totalAmount,
    required super.createdAt,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.subtotalAmount,
    required this.shippingFee,
    required this.discountAmount,
    this.note,
    this.items = const [],
    this.statusHistory = const [],
  });

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) {
    final base = OrderDto.fromJson(json);
    return OrderDetailDto(
      id: base.id,
      orderCode: base.orderCode,
      status: base.status,
      paymentMethod: base.paymentMethod,
      paymentStatus: base.paymentStatus,
      totalAmount: base.totalAmount,
      createdAt: base.createdAt,
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      subtotalAmount: (json['subtotalAmount'] as num? ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] as num? ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      note: json['note'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => OrderItemDto.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      statusHistory:
          (json['statusHistory'] as List<dynamic>?)
              ?.map(
                (history) => OrderStatusHistoryDto.fromJson(
                  history as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  @override
  OrderDetail toDomain() {
    return OrderDetail(
      id: id,
      orderCode: orderCode,
      status: OrderStatus.fromString(status),
      totalAmount: totalAmount,
      createdAt: createdAt,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      shippingAddress: shippingAddress,
      paymentMethod: PaymentMethod.fromString(paymentMethod),
      paymentStatus: paymentStatus,
      subtotalAmount: subtotalAmount,
      shippingFee: shippingFee,
      discountAmount: discountAmount,
      note: note,
      items: items.map((item) => item.toDomain()).toList(),
      statusHistory: statusHistory.map((item) => item.toDomain()).toList(),
    );
  }
}

List<Order> orderListFromJson(dynamic json) {
  return (json as List<dynamic>)
      .map((item) => OrderDto.fromJson(item as Map<String, dynamic>).toDomain())
      .toList();
}

Order orderSummaryFromJson(dynamic json) {
  return OrderDto.fromJson(json as Map<String, dynamic>).toDomain();
}

OrderDetail orderDetailFromJson(dynamic json) {
  return OrderDetailDto.fromJson(json as Map<String, dynamic>).toDomain();
}
