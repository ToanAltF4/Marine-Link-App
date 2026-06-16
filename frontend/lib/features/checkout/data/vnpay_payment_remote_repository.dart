import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../domain/vnpay_payment.dart';

class VnpayPaymentRemoteRepository implements VnpayPaymentRepository {
  final ApiClient apiClient;

  const VnpayPaymentRemoteRepository({required this.apiClient});

  @override
  Future<VnpayPaymentUrl> createPaymentUrl({required String orderId}) async {
    final response = await apiClient.post<VnpayPaymentUrl>(
      ApiEndpoints.vnpayPaymentUrl,
      data: {'orderId': orderId},
      fromJson: _paymentUrlFromJson,
    );
    final data = response.data;
    if (!response.success || data == null) {
      throw ApiException(
        message: response.message ?? 'Không thể tạo liên kết thanh toán VNPAY',
        type: ApiExceptionType.server,
      );
    }
    return data;
  }

  @override
  Future<VnpayPaymentResult> cancelPayment({required String orderId}) async {
    final response = await apiClient.post<VnpayPaymentResult>(
      ApiEndpoints.vnpayCancel,
      data: {'orderId': orderId},
      fromJson: _paymentResultFromJson,
    );
    final data = response.data;
    if (!response.success || data == null) {
      throw ApiException(
        message: response.message ?? 'Không thể hủy thanh toán VNPAY',
        type: ApiExceptionType.server,
      );
    }
    return data;
  }

  VnpayPaymentUrl _paymentUrlFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return VnpayPaymentUrl(
      orderId: map['orderId'] as String? ?? '',
      orderCode: map['orderCode'] as String? ?? '',
      txnRef: map['txnRef'] as String? ?? '',
      paymentUrl: map['paymentUrl'] as String? ?? '',
    );
  }

  VnpayPaymentResult _paymentResultFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return VnpayPaymentResult(
      txnRef: map['txnRef'] as String?,
      orderCode: map['orderCode'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
      responseCode: map['responseCode'] as String?,
      message: map['message'] as String?,
    );
  }
}
