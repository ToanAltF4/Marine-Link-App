// ignore_for_file: prefer_initializing_formals

import '../../../core/api/api_response.dart';
import '../../../core/api/api_client.dart';
import '../../cart/domain/cart.dart';
import '../../orders/domain/order.dart';
import '../../orders/domain/order_repository.dart';
import 'cart_sync_repository.dart';
import '../domain/checkout_repository.dart';
import '../domain/vnpay_payment.dart';

class OrderCheckoutRepository implements CheckoutRepository {
  final OrderRepository _orderRepository;
  final CartSyncRepository? _cartSyncRepository;
  final VnpayPaymentRepository? _vnpayPaymentRepository;

  const OrderCheckoutRepository({
    required OrderRepository orderRepository,
    CartSyncRepository? cartSyncRepository,
    VnpayPaymentRepository? vnpayPaymentRepository,
  }) : _orderRepository = orderRepository,
       _cartSyncRepository = cartSyncRepository,
       _vnpayPaymentRepository = vnpayPaymentRepository;

  @override
  Future<ApiResponse<CheckoutResult>> createOrder({
    required CheckoutRequest request,
    required Cart activeCart,
  }) async {
    if (activeCart.selectedItems.isEmpty) {
      return const ApiResponse<CheckoutResult>(
        success: false,
        message:
            '\u0110\u01a1n h\u00e0ng c\u1ea7n c\u00f3 \u00edt nh\u1ea5t m\u1ed9t s\u1ea3n ph\u1ea9m',
      );
    }

    final invalidItems = activeCart.selectedItems.where(
      (item) => !item.isValid,
    );
    if (invalidItems.isNotEmpty) {
      return const ApiResponse<CheckoutResult>(
        success: false,
        message:
            'Gi\u1ecf h\u00e0ng c\u00f3 s\u1ea3n ph\u1ea9m kh\u00f4ng h\u1ee3p l\u1ec7',
      );
    }

    try {
      final cartSyncRepository = _cartSyncRepository;
      if (cartSyncRepository != null) {
        await _trySyncCart(cartSyncRepository, activeCart);
      }

      final response = await _orderRepository.createOrder(
        receiverName: request.receiverName,
        receiverPhone: request.receiverPhone,
        shippingAddress: request.shippingAddress,
        shippingAddressId: request.shippingAddressId,
        paymentMethod: request.paymentMethod.apiValue,
        note: request.note,
        items: activeCart.selectedItems
            .map(
              (item) => OrderCreateItemInput(
                productId: item.productId,
                quantity: item.quantity,
              ),
            )
            .toList(),
      );

      if (!response.success || response.data == null) {
        return ApiResponse<CheckoutResult>(
          success: false,
          message:
              response.message ??
              'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n h\u00e0ng',
          errors: response.errors,
        );
      }

      final vnpayPayment = await _createVnpayPaymentIfNeeded(
        request: request,
        orderId: response.data!.id,
      );

      return ApiResponse<CheckoutResult>(
        success: true,
        message: response.message,
        data: CheckoutResult(
          order: response.data!,
          subtotalAmount: activeCart.subtotalAmount,
          totalItemCount: activeCart.totalSelectedItemCount,
          vnpayPayment: vnpayPayment,
        ),
      );
    } on ApiException catch (exception) {
      return ApiResponse<CheckoutResult>(
        success: false,
        message: exception.message,
      );
    }
  }

  Future<VnpayPaymentUrl?> _createVnpayPaymentIfNeeded({
    required CheckoutRequest request,
    required String orderId,
  }) async {
    if (request.paymentMethod != PaymentMethod.vnpay) {
      return null;
    }
    final repository = _vnpayPaymentRepository;
    if (repository == null) {
      return null;
    }
    return repository.createPaymentUrl(orderId: orderId);
  }

  Future<void> _trySyncCart(
    CartSyncRepository cartSyncRepository,
    Cart activeCart,
  ) async {
    try {
      await cartSyncRepository.syncCart(activeCart);
    } on ApiException {
      // Checkout sends selected items with POST /api/orders, so cart sync is
      // best-effort until the full Cart API is the source of truth.
    }
  }
}
