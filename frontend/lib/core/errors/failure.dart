import 'package:marinelink/core/constants/app_strings.dart';

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
  const NetworkFailure([super.message = AppStrings.noNetwork]);
}

/// HTTP 401: token missing or expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = AppStrings.sessionExpiredLogin]);
}

/// HTTP 403: authenticated but not allowed.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = AppStrings.forbiddenAction]);
}

/// HTTP 404: resource not found or hidden.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = AppStrings.dataNotFound]);
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
  const ServerFailure([super.message = AppStrings.serverErrorLater]);
}

/// Unexpected error not covered by the above.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = AppStrings.unknownErrorTryAgain]);
}
