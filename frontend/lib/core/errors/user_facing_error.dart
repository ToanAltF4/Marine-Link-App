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
    ApiExceptionType.network => 'Kết nối không ổn định. Vui lòng thử lại.',
    ApiExceptionType.unauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ApiExceptionType.forbidden => 'Bạn không có quyền thực hiện thao tác này.',
    ApiExceptionType.notFound => 'Không tìm thấy dữ liệu.',
    ApiExceptionType.validation =>
      'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
    ApiExceptionType.server => 'Hệ thống đang gặp lỗi. Vui lòng thử lại sau.',
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
    'validation failed' => 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
    'authentication required' =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'invalid authentication subject' =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'access denied' => 'Bạn không có quyền thực hiện thao tác này.',
    'internal server error' => 'Hệ thống đang gặp lỗi. Vui lòng thử lại sau.',
    'invalid_credentials' => 'Email/số điện thoại hoặc mật khẩu không đúng.',
    'email_already_exists' => 'Email đã được sử dụng.',
    'phone_already_exists' => 'Số điện thoại đã được sử dụng.',
    'otp_invalid' => 'Mã OTP không chính xác.',
    'otp_expired' => 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.',
    'not_found' => 'Không tìm thấy dữ liệu.',
    'user not found' => 'Không tìm thấy người dùng.',
    'notification not found' => 'Không tìm thấy thông báo.',
    'chat room not found' => 'Không tìm thấy phòng chat.',
    'chat message not found' => 'Không tìm thấy tin nhắn.',
    'khong tim thay nguoi dung' => 'Không tìm thấy người dùng.',
    'khong tim thay san pham' => 'Không tìm thấy sản phẩm.',
    'khong tim thay don hang' => 'Không tìm thấy đơn hàng.',
    'khong tim thay dia chi giao hang' => 'Không tìm thấy địa chỉ giao hàng.',
    'khong tim thay giao dich thanh toan' =>
      'Không tìm thấy giao dịch thanh toán.',
    'san pham khong kha dung' => 'Sản phẩm không khả dụng.',
    'so luong dat hang duoi muc toi thieu' =>
      'Số lượng đặt hàng dưới mức tối thiểu.',
    'san pham khong du ton kho' => 'Sản phẩm không đủ tồn kho.',
    'gio hang dang trong' => 'Giỏ hàng đang trống.',
    'phuong thuc thanh toan khong hop le' =>
      'Phương thức thanh toán không hợp lệ.',
    'khong the chuyen trang thai don hang' =>
      'Không thể chuyển trạng thái đơn hàng.',
    'don hang chua thanh toan' => 'Đơn hàng chưa thanh toán.',
    'don hang khong su dung vnpay' => 'Đơn hàng không sử dụng VNPAY.',
    'don hang da thanh toan' => 'Đơn hàng đã thanh toán.',
    'chi co the huy don dang cho thanh toan' =>
      'Chỉ có thể hủy đơn đang chờ thanh toán.',
    'chua cau hinh vnpay' => 'Chưa cấu hình VNPAY.',
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
