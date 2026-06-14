import 'package:equatable/equatable.dart';
import '../../domain/user.dart';

/// Auth BLoC states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking token / loading login/register.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Successfully authenticated.
class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user.id, token];
}

/// Not authenticated (logged out or no token).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Registration complete — OTP has been sent. Navigate to OTP screen.
class AuthOtpSent extends AuthState {
  final String email;

  const AuthOtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// OTP successfully verified — account is now active. Navigate to login.
class AuthEmailVerified extends AuthState {
  const AuthEmailVerified();
}

/// OTP resent successfully.
class AuthOtpResent extends AuthState {
  const AuthOtpResent();
}

/// Registration was accepted; account waits for approval before login.
class AuthRegistrationSuccess extends AuthState {
  const AuthRegistrationSuccess();
}

/// Password changed successfully.
class AuthPasswordChangeSuccess extends AuthState {
  const AuthPasswordChangeSuccess();
}

/// Login/register failed.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
