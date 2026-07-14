import 'package:marinelink/core/constants/app_strings.dart';
import '../api/api_client.dart';

String userFacingErrorMessage(Object error, {required String fallback}) {
  if (error is ApiException) {
    final message = userFacingResponseMessage(error.message, fallback: '');
    if (message.isNotEmpty) {
      return message;
    }
    return _fallbackForType(error.type, fallback);
  }

  return userFacingResponseMessage(error.toString(), fallback: fallback);
}

String userFacingResponseMessage(String? message, {required String fallback}) {
  final cleaned = _cleanMessage(message);
  if (cleaned == null) {
    return fallback;
  }

  final known = _knownMessage(cleaned);
  if (known != null) {
    return known;
  }

  if (_looksTechnical(cleaned)) {
    return fallback;
  }

  return cleaned;
}

String _fallbackForType(ApiExceptionType type, String fallback) {
  return switch (type) {
    ApiExceptionType.network => AppStrings.unstableConnection,
    ApiExceptionType.unauthorized => AppStrings.sessionExpiredLoginAlt,
    ApiExceptionType.forbidden => AppStrings.forbiddenAction,
    ApiExceptionType.notFound => AppStrings.dataNotFound,
    ApiExceptionType.validation => AppStrings.invalidInfoCheckAgain,
    ApiExceptionType.server => AppStrings.systemFacingError,
    ApiExceptionType.unknown => fallback,
  };
}

String? _cleanMessage(String? message) {
  if (message == null) {
    return null;
  }

  var value = message.trim();
  if (value.isEmpty) {
    return null;
  }

  value = value.replaceFirst(RegExp(r'^Exception:\s*'), '');
  value = value.replaceFirst(RegExp(r'^ApiException\([^)]*\):\s*'), '');
  value = value.replaceFirst(RegExp(r'^(HTTP\s*)?\d{3}\s*[:\-]\s*'), '');
  value = value.replaceFirst(RegExp(r'^\[[A-Z0-9_]+\]\s*'), '');
  value = value.trim();

  return value.isEmpty ? null : value;
}

String? _knownMessage(String message) {
  final normalized = message.toLowerCase();
  return switch (normalized) {
    'ok' => null,
    'validation failed' => AppStrings.invalidInfoCheckAgain,
    'authentication required' => AppStrings.sessionExpiredLoginAlt,
    'invalid authentication subject' => AppStrings.sessionExpiredLoginAlt,
    'access denied' => AppStrings.forbiddenAction,
    'internal server error' => AppStrings.systemFacingError,
    'invalid_credentials' => AppStrings.invalidCredentials,
    'email_already_exists' => AppStrings.emailAlreadyUsed,
    'phone_already_exists' => AppStrings.phoneAlreadyUsed,
    'otp_invalid' => AppStrings.otpInvalid,
    'otp_expired' => AppStrings.otpExpiredRequestNew,
    'not_found' => AppStrings.dataNotFound,
    'user not found' => AppStrings.userNotFound,
    'notification not found' => AppStrings.notificationNotFound,
    'chat room not found' => AppStrings.chatRoomNotFound,
    'chat message not found' => AppStrings.chatMessageNotFound,
    'khong tim thay nguoi dung' => AppStrings.userNotFound,
    'khong tim thay san pham' => AppStrings.productDetailNotFound,
    'khong tim thay don hang' => AppStrings.orderDetailNotFound,
    'khong tim thay dia chi giao hang' => AppStrings.shippingAddressNotFound,
    'khong tim thay giao dich thanh toan' =>
      AppStrings.paymentTransactionNotFound,
    'san pham khong kha dung' => AppStrings.productUnavailable,
    'so luong dat hang duoi muc toi thieu' =>
      AppStrings.orderQuantityBelowMinimum,
    'san pham khong du ton kho' => AppStrings.productInsufficientStock,
    'gio hang dang trong' => AppStrings.cartEmptyWithPeriod,
    'phuong thuc thanh toan khong hop le' => AppStrings.invalidPaymentMethod,
    'khong the chuyen trang thai don hang' =>
      AppStrings.orderStatusTransitionInvalid,
    'don hang chua thanh toan' => AppStrings.orderUnpaidWithPeriod,
    'don hang khong su dung vnpay' => AppStrings.orderNotVnpay,
    'don hang da thanh toan' => AppStrings.orderPaid,
    'chi co the huy don dang cho thanh toan' =>
      AppStrings.onlyCancelPendingPayment,
    'chua cau hinh vnpay' => AppStrings.vnpayNotConfigured,
    _ => null,
  };
}

bool _looksTechnical(String message) {
  if (message.contains('ApiException(') ||
      message.contains('DioException') ||
      message.contains('java.') ||
      message.contains('org.springframework') ||
      message.contains('StackTrace') ||
      message.contains('{') ||
      message.contains('}')) {
    return true;
  }

  if (RegExp(
    r'\b(status|code)\s*[:=]\s*\d{3}\b',
    caseSensitive: false,
  ).hasMatch(message)) {
    return true;
  }

  return RegExp(r'^[A-Z][A-Z0-9_]{2,}$').hasMatch(message);
}
