part of 'order_bloc.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch paginated order list (USER: own orders, STAFF/ADMIN: all/assigned).
class OrderListRequested extends OrderEvent {
  final int page;
  final int size;
  final String? status;
  final String? fromDate;
  final String? toDate;

  const OrderListRequested({
    this.page = 0,
    this.size = 20,
    this.status,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [page, size, status, fromDate, toDate];
}

/// Fetch full order detail.
class OrderDetailRequested extends OrderEvent {
  final String orderId;

  const OrderDetailRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Create a new order from the synced cart (POST /api/orders).
class OrderCreateRequested extends OrderEvent {
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final String paymentMethod;
  final String? note;

  const OrderCreateRequested({
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.paymentMethod,
    this.note,
  });

  @override
  List<Object?> get props => [
    receiverName,
    receiverPhone,
    shippingAddress,
    paymentMethod,
    note,
  ];
}

/// Update order status (Staff/Admin only).
class OrderStatusUpdateRequested extends OrderEvent {
  final String orderId;
  final String newStatus;
  final String? note;

  const OrderStatusUpdateRequested({
    required this.orderId,
    required this.newStatus,
    this.note,
  });

  @override
  List<Object?> get props => [orderId, newStatus, note];
}
