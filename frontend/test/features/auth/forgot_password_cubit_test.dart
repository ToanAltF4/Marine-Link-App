import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/auth/data/auth_mock_repository.dart';
import 'package:marinelink/features/auth/presentation/cubit/forgot_password_cubit.dart';

const _email = 'daily-a@marinelink.demo';
const _validOtp = '123456';
const _invalidOtp = '000000';
const _newPassword = 'newpass123';

void main() {
  group('ForgotPasswordCubit', () {
    test('initial state is ForgotPasswordState.initial', () {
      final cubit = ForgotPasswordCubit(authRepository: AuthMockRepository());
      expect(cubit.state.status, ForgotPasswordStatus.initial);
      cubit.close();
    });

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [loading, otpSent] when requestOtp succeeds',
      build: () => ForgotPasswordCubit(authRepository: AuthMockRepository()),
      act: (cubit) => cubit.requestOtp(_email),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<ForgotPasswordState>().having(
          (s) => s.status,
          'status',
          ForgotPasswordStatus.loading,
        ),
        isA<ForgotPasswordState>()
            .having((s) => s.status, 'status', ForgotPasswordStatus.otpSent)
            .having((s) => s.email, 'email', _email),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [loading, success] when resetPassword succeeds',
      build: () => ForgotPasswordCubit(authRepository: AuthMockRepository()),
      act: (cubit) => cubit.resetPassword(
        email: _email,
        otpCode: _validOtp,
        newPassword: _newPassword,
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<ForgotPasswordState>().having(
          (s) => s.status,
          'status',
          ForgotPasswordStatus.loading,
        ),
        isA<ForgotPasswordState>().having(
          (s) => s.status,
          'status',
          ForgotPasswordStatus.success,
        ),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [loading, failure] when resetPassword OTP is invalid',
      build: () => ForgotPasswordCubit(authRepository: AuthMockRepository()),
      act: (cubit) => cubit.resetPassword(
        email: _email,
        otpCode: _invalidOtp,
        newPassword: _newPassword,
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<ForgotPasswordState>().having(
          (s) => s.status,
          'status',
          ForgotPasswordStatus.loading,
        ),
        isA<ForgotPasswordState>()
            .having((s) => s.status, 'status', ForgotPasswordStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Mã OTP không tồn tại hoặc đã được sử dụng',
            ),
      ],
    );
  });
}
