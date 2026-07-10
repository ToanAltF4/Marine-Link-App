// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/auth_exceptions.dart';
import '../../domain/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc handles login, register, OTP verification, logout and token persistence.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthVerifyEmailRequested>(_onVerifyEmailRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthChangePasswordRequested>(_onChangePasswordRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user, token: ''));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.login(
        emailOrPhone: event.emailOrPhone,
        password: event.password,
      );
      emit(AuthAuthenticated(user: result.user, token: result.token));
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.loginFailed),
        ),
      );
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.loginWithGoogle();
      emit(AuthAuthenticated(user: result.user, token: result.token));
    } on GoogleSignInCancelled {
      // User dismissed the picker — return silently, no error message.
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.googleLoginFailed),
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.register(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        storeName: event.storeName,
        businessAddress: event.businessAddress,
        taxCode: event.taxCode,
      );
      // After successful registration, an OTP has been sent to the user's email.
      emit(AuthOtpSent(email: event.email));
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.registerFailed),
        ),
      );
    }
  }

  Future<void> _onVerifyEmailRequested(
    AuthVerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.verifyEmail(
        email: event.email,
        otpCode: event.otpCode,
      );
      emit(const AuthEmailVerified());
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.verifyEmailFailed),
        ),
      );
    }
  }

  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.resendOtp(email: event.email);
      emit(const AuthOtpResent());
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.resendOtpFailed),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  Future<void> _onChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(const AuthLoading());
    try {
      await _authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(const AuthPasswordChangeSuccess());

      if (currentState is AuthAuthenticated) {
        emit(currentState);
      }
    } catch (e) {
      emit(
        AuthFailure(
          userFacingErrorMessage(e, fallback: AppStrings.changePasswordFailed),
        ),
      );
      if (currentState is AuthAuthenticated) {
        emit(currentState);
      }
    }
  }
}
