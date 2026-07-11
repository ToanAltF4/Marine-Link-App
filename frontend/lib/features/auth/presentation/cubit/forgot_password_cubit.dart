import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/auth_repository.dart';

part 'forgot_password_state.dart';

/// Drives the two-step "Quên mật khẩu" flow:
/// 1. [requestOtp] → POST /api/auth/forgot-password (always 204).
/// 2. [resetPassword] → POST /api/auth/reset-password.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordCubit({required this.authRepository})
    : super(const ForgotPasswordState());

  Future<void> requestOtp(String email) async {
    final normalized = email.trim();
    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        email: normalized,
        clearError: true,
      ),
    );
    try {
      await authRepository.forgotPassword(email: normalized);
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.otpSent,
          email: normalized,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: userFacingErrorMessage(
            e,
            fallback: AppStrings.forgotPasswordFailed,
          ),
        ),
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    emit(
      state.copyWith(status: ForgotPasswordStatus.loading, clearError: true),
    );
    try {
      await authRepository.resetPassword(
        email: email.trim(),
        otpCode: otpCode,
        newPassword: newPassword,
      );
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.success,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: userFacingErrorMessage(
            e,
            fallback: AppStrings.resetPasswordFailed,
          ),
        ),
      );
    }
  }
}
