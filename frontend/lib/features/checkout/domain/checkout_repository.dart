import 'package:equatable/equatable.dart';

import '../../../core/api/api_response.dart';
import '../../cart/domain/cart.dart';
import '../../orders/domain/order.dart';

class CheckoutRequest extends Equatable {
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final String? shippingAddressId;
  final PaymentMethod paymentMethod;
  final String? note;

  const CheckoutRequest({
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    this.shippingAddressId,
    required this.paymentMethod,
    this.note,
  });

  @override
  List<Object?> get props => [
    receiverName,
    receiverPhone,
    shippingAddress,
    shippingAddressId,
    paymentMethod,
    note,
  ];
}

class CheckoutResult extends Equatable {
  final Order order;
  final double subtotalAmount;
  final int totalItemCount;

  const CheckoutResult({
    required this.order,
    required this.subtotalAmount,
    required this.totalItemCount,
  });

  @override
  List<Object?> get props => [order, subtotalAmount, totalItemCount];
}

abstract class CheckoutRepository {
  Future<ApiResponse<CheckoutResult>> createOrder({
    required CheckoutRequest request,
    required Cart activeCart,
  });
}
