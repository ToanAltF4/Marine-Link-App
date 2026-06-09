import 'package:equatable/equatable.dart';

/// Auth BLoC events.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String emailOrPhone;
  final String password;

  const AuthLoginRequested({
    required this.emailOrPhone,
    required this.password,
  });

  @override
  List<Object?> get props => [emailOrPhone];
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String? storeName;
  final String? businessAddress;
  final String? taxCode;

  const AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.storeName,
    this.businessAddress,
    this.taxCode,
  });

  @override
  List<Object?> get props => [email, phone];
}

class AuthVerifyEmailRequested extends AuthEvent {
  final String email;
  final String otpCode;

  const AuthVerifyEmailRequested({
    required this.email,
    required this.otpCode,
  });

  @override
  List<Object?> get props => [email, otpCode];
}

class AuthResendOtpRequested extends AuthEvent {
  final String email;

  const AuthResendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const AuthChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
