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
  const NetworkFailure([
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
  ]);
}

/// HTTP 401: token missing or expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
  ]);
}

/// HTTP 403: authenticated but not allowed.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'Bạn không có quyền thực hiện thao tác này.',
  ]);
}

/// HTTP 404: resource not found or hidden.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Không tìm thấy dữ liệu.']);
}

/// HTTP 422 or validation error.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// HTTP 409: conflict (duplicate, invalid state transition).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// HTTP 5xx or unknown server error.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi hệ thống. Vui lòng thử lại sau.']);
}

/// Unexpected error not covered by the above.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Đã có lỗi xảy ra. Vui lòng thử lại.']);
}
