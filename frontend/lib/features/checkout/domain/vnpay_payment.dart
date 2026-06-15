import 'package:equatable/equatable.dart';

class VnpayPaymentUrl extends Equatable {
  final String orderId;
  final String orderCode;
  final String txnRef;
  final String paymentUrl;

  const VnpayPaymentUrl({
    required this.orderId,
    required this.orderCode,
    required this.txnRef,
    required this.paymentUrl,
  });

  @override
  List<Object?> get props => [orderId, orderCode, txnRef, paymentUrl];
}

class VnpayPaymentResult extends Equatable {
  final String? txnRef;
  final String? orderCode;
  final String? paymentStatus;
  final String? responseCode;
  final String? message;

  const VnpayPaymentResult({
    this.txnRef,
    this.orderCode,
    this.paymentStatus,
    this.responseCode,
    this.message,
  });

  @override
  List<Object?> get props => [
    txnRef,
    orderCode,
    paymentStatus,
    responseCode,
    message,
  ];
}

abstract class VnpayPaymentRepository {
  Future<VnpayPaymentUrl> createPaymentUrl({required String orderId});

  Future<VnpayPaymentResult> cancelPayment({required String orderId});
}
