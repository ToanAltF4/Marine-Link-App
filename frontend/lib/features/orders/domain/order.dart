import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipping,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'PENDING' => OrderStatus.pending,
      'CONFIRMED' => OrderStatus.confirmed,
      'SHIPPING' => OrderStatus.shipping,
      'COMPLETED' => OrderStatus.completed,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  String get apiValue => name.toUpperCase();

  String get displayLabel => switch (this) {
    OrderStatus.pending => 'Chờ duyệt',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.shipping => 'Đang giao',
    OrderStatus.completed => 'Hoàn tất',
    OrderStatus.cancelled => 'Đã hủy',
  };

  List<OrderStatus> get allowedTransitions => switch (this) {
    OrderStatus.pending => [OrderStatus.confirmed, OrderStatus.cancelled],
    OrderStatus.confirmed => [OrderStatus.shipping, OrderStatus.cancelled],
    OrderStatus.shipping => [OrderStatus.completed],
    OrderStatus.completed => [],
    OrderStatus.cancelled => [],
  };
}

enum PaymentMethod {
  cod,
  bankTransfer,
  vnpay;

  static PaymentMethod fromString(String value) {
    return switch (value.toUpperCase()) {
      'BANK_TRANSFER' => PaymentMethod.bankTransfer,
      'VNPAY' => PaymentMethod.vnpay,
      _ => PaymentMethod.cod,
    };
  }

  String get apiValue => switch (this) {
    PaymentMethod.cod => 'COD',
    PaymentMethod.bankTransfer => 'BANK_TRANSFER',
    PaymentMethod.vnpay => 'VNPAY',
  };

  String get displayLabel => switch (this) {
    PaymentMethod.cod => 'Thanh toán khi nhận hàng (COD)',
    PaymentMethod.bankTransfer => 'Chuyển khoản ngân hàng',
    PaymentMethod.vnpay => 'VNPAY QR',
  };
}

class OrderItem extends Equatable {
  final String productId;
  final String productNameSnapshot;
  final String productUnitSnapshot;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productNameSnapshot,
    required this.productUnitSnapshot,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [
    productId,
    productNameSnapshot,
    productUnitSnapshot,
    productImageUrl,
    unitPrice,
    quantity,
  ];
}

class OrderStatusHistory extends Equatable {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;

  const OrderStatusHistory({
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [fromStatus, toStatus, note, createdAt];
}

class Order extends Equatable {
  final String id;
  final String orderCode;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderCode,
    required this.status,
    this.paymentMethod = PaymentMethod.cod,
    this.paymentStatus = 'UNPAID',
    required this.totalAmount,
    required this.createdAt,
  });

  bool get isWaitingForPayment {
    if (status != OrderStatus.pending) {
      return false;
    }
    final methodRequiresPayment =
        paymentMethod == PaymentMethod.bankTransfer ||
        paymentMethod == PaymentMethod.vnpay;
    return methodRequiresPayment && paymentStatus.toUpperCase() != 'PAID';
  }

  String get displayStatusLabel =>
      isWaitingForPayment ? 'Chờ thanh toán' : status.displayLabel;

  @override
  List<Object?> get props => [
    id,
    orderCode,
    status,
    paymentMethod,
    paymentStatus,
    totalAmount,
    createdAt,
  ];
}

class OrderDetail extends Order {
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final double subtotalAmount;
  final double shippingFee;
  final double discountAmount;
  final String? note;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;

  const OrderDetail({
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
    required this.items,
    required this.statusHistory,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    receiverName,
    receiverPhone,
    shippingAddress,
    paymentMethod,
    paymentStatus,
    subtotalAmount,
    shippingFee,
    discountAmount,
    note,
    items,
    statusHistory,
  ];
}
