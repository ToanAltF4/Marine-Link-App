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

/// Login/register failed.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
