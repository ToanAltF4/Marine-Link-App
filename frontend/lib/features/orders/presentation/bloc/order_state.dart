part of 'order_bloc.dart';

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

// ── List states ───────────────────────────────────────────────────────────────

class OrderListLoading extends OrderState {
  const OrderListLoading();
}

class OrderListLoaded extends OrderState {
  final List<Order> orders;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const OrderListLoaded({
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [orders, currentPage, totalPages];
}

class OrderListEmpty extends OrderState {
  const OrderListEmpty();
}

class OrderListError extends OrderState {
  final String message;

  const OrderListError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Detail states ─────────────────────────────────────────────────────────────

class OrderDetailLoading extends OrderState {
  const OrderDetailLoading();
}

class OrderDetailLoaded extends OrderState {
  final OrderDetail order;

  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderDetailError extends OrderState {
  final String message;

  const OrderDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Create states ─────────────────────────────────────────────────────────────

class OrderCreateLoading extends OrderState {
  const OrderCreateLoading();
}

class OrderCreateSuccess extends OrderState {
  final Order order;

  const OrderCreateSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderCreateError extends OrderState {
  final String message;

  const OrderCreateError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Status update states ──────────────────────────────────────────────────────

class OrderStatusUpdateLoading extends OrderState {
  const OrderStatusUpdateLoading();
}

class OrderStatusUpdateSuccess extends OrderState {
  final String orderId;
  final String newStatus;

  const OrderStatusUpdateSuccess({
    required this.orderId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [orderId, newStatus];
}

class OrderStatusUpdateError extends OrderState {
  final String message;

  const OrderStatusUpdateError(this.message);

  @override
  List<Object?> get props => [message];
}
