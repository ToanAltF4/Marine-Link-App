// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/order.dart';
import '../../domain/order_repository.dart';

part 'order_event.dart';
part 'order_state.dart';

/// OrderBloc handles order list, detail, creation, and status updates.
///
/// Repository is injected — switch from OrderMockRepository to
/// OrderRemoteRepository in Sprint 5 via DI without changing this bloc.
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;

  OrderBloc({required OrderRepository orderRepository})
    : _orderRepository = orderRepository,
      super(const OrderInitial()) {
    on<OrderListRequested>(_onListRequested);
    on<OrderDetailRequested>(_onDetailRequested);
    on<OrderCreateRequested>(_onCreateRequested);
    on<OrderStatusUpdateRequested>(_onStatusUpdateRequested);
  }

  Future<void> _onListRequested(
    OrderListRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderListLoading());
    try {
      final response = await _orderRepository.getOrders(
        page: event.page,
        size: event.size,
        status: event.status,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (!response.success || response.data == null) {
        emit(OrderListError(response.message ?? 'Lỗi tải danh sách đơn hàng'));
        return;
      }

      final orders = response.data!;
      if (orders.isEmpty) {
        emit(const OrderListEmpty());
      } else {
        final pagination = response.pagination;
        emit(
          OrderListLoaded(
            orders: orders,
            currentPage: pagination?.page ?? 0,
            totalPages: pagination?.totalPages ?? 1,
            hasMore:
                pagination != null &&
                pagination.page < pagination.totalPages - 1,
          ),
        );
      }
    } catch (e) {
      emit(OrderListError(e.toString()));
    }
  }

  Future<void> _onDetailRequested(
    OrderDetailRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderDetailLoading());
    try {
      final response = await _orderRepository.getOrderDetail(event.orderId);

      if (!response.success || response.data == null) {
        emit(OrderDetailError(response.message ?? 'Không tìm thấy đơn hàng'));
        return;
      }

      emit(OrderDetailLoaded(response.data!));
    } catch (e) {
      emit(OrderDetailError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    OrderCreateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderCreateLoading());
    try {
      final response = await _orderRepository.createOrder(
        receiverName: event.receiverName,
        receiverPhone: event.receiverPhone,
        shippingAddress: event.shippingAddress,
        paymentMethod: event.paymentMethod,
        note: event.note,
      );

      if (!response.success || response.data == null) {
        emit(OrderCreateError(response.message ?? 'Lỗi tạo đơn hàng'));
        return;
      }

      emit(OrderCreateSuccess(response.data!));
    } catch (e) {
      emit(OrderCreateError(e.toString()));
    }
  }

  Future<void> _onStatusUpdateRequested(
    OrderStatusUpdateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderStatusUpdateLoading());
    try {
      final response = await _orderRepository.updateOrderStatus(
        orderId: event.orderId,
        newStatus: event.newStatus,
        note: event.note,
      );

      if (!response.success) {
        emit(
          OrderStatusUpdateError(
            response.message ?? 'Lỗi cập nhật trạng thái đơn hàng',
          ),
        );
        return;
      }

      emit(
        OrderStatusUpdateSuccess(
          orderId: event.orderId,
          newStatus: event.newStatus,
        ),
      );
    } catch (e) {
      emit(OrderStatusUpdateError(e.toString()));
    }
  }
}
