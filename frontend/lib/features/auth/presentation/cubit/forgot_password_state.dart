part of 'forgot_password_cubit.dart';

enum ForgotPasswordStatus { initial, loading, otpSent, success, failure }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;
  final String email;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.email = '',
    this.errorMessage,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, email, errorMessage];
}
