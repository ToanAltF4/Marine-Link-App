/// Failure types returned by repositories and BLoC/Cubit.
///
/// UI should map these to user-friendly Vietnamese messages.
/// Never display raw backend error strings.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Network connectivity issue or timeout.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.'])
      : super(message);
}

/// HTTP 401 — token missing or expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'])
      : super(message);
}

/// HTTP 403 — authenticated but not allowed.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String message = 'Bạn không có quyền thực hiện thao tác này.'])
      : super(message);
}

/// HTTP 404 — resource not found or hidden.
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Không tìm thấy dữ liệu.'])
      : super(message);
}

/// HTTP 422 or validation error.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// HTTP 409 — conflict (duplicate, invalid state transition).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// HTTP 5xx or unknown server error.
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Lỗi hệ thống. Vui lòng thử lại sau.'])
      : super(message);
}

/// Unexpected error not covered by the above.
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Đã có lỗi xảy ra. Vui lòng thử lại.'])
      : super(message);
}
