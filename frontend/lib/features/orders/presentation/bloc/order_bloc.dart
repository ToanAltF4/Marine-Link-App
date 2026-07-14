// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';
import '../../../../core/errors/user_facing_error.dart';
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
        emit(
          OrderListError(
            userFacingResponseMessage(
              response.message,
              fallback: AppStrings.orderListLoadError,
            ),
          ),
        );
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
      emit(
        OrderListError(
          userFacingErrorMessage(e, fallback: AppStrings.orderListLoadError),
        ),
      );
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
        emit(
          OrderDetailError(
            userFacingResponseMessage(
              response.message,
              fallback: AppStrings.orderDetailNotFound,
            ),
          ),
        );
        return;
      }

      emit(OrderDetailLoaded(response.data!));
    } catch (e) {
      emit(
        OrderDetailError(
          userFacingErrorMessage(e, fallback: AppStrings.orderDetailNotFound),
        ),
      );
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
        emit(
          OrderCreateError(
            userFacingResponseMessage(
              response.message,
              fallback: AppStrings.orderCreateError,
            ),
          ),
        );
        return;
      }

      emit(OrderCreateSuccess(response.data!));
    } catch (e) {
      emit(
        OrderCreateError(
          userFacingErrorMessage(e, fallback: AppStrings.orderCreateError),
        ),
      );
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
            userFacingResponseMessage(
              response.message,
              fallback: AppStrings.orderStatusUpdateError,
            ),
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
      emit(
        OrderStatusUpdateError(
          userFacingErrorMessage(
            e,
            fallback: AppStrings.orderStatusUpdateError,
          ),
        ),
      );
    }
  }
}
