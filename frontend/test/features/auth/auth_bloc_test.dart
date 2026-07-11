import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/features/auth/data/auth_mock_repository.dart';
import 'package:marinelink/features/auth/domain/auth_repository.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_event.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';

const _dailyCredential = 'Daily@123';
const _adminCredential = 'Admin@123';
const _staffCredential = 'Staff@123';
const _invalidCredential = 'wrong-password';
const _invalidOldValue = 'wrong';
const _currentCredential = 'correct';
const _replacementCredential = 'new-password';
const _oldValue = 'old';
const _newValue = 'new';

void main() {
  late AuthBloc authBloc;

  setUp(() {
    authBloc = AuthBloc(authRepository: AuthMockRepository());
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('auth events expose stable props', () {
      expect(
        const AuthLoginRequested(
          emailOrPhone: 'daily-a@marinelink.demo',
          password: _dailyCredential,
        ).props,
        ['daily-a@marinelink.demo'],
      );
      expect(
        const AuthRegisterRequested(
          fullName: 'Nguyen Van A',
          email: 'daily-new@example.com',
          phone: '0912345678',
          password: _dailyCredential,
        ).props,
        ['daily-new@example.com', '0912345678'],
      );
      expect(const AuthCheckRequested().props, isEmpty);
      expect(const AuthLogoutRequested().props, isEmpty);
      expect(
        const AuthChangePasswordRequested(
          oldPassword: _oldValue,
          newPassword: _newValue,
        ).props,
        ['old', 'new'],
      );
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when check requested with no session',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful admin login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          emailOrPhone: 'admin@marinelink.demo',
          password: _adminCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isAdmin, 'isAdmin', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful Google login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthGoogleLoginRequested()),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>()
            .having((s) => s.user.email, 'email', 'google-demo@gmail.com')
            .having((s) => s.user.isUser, 'isUser', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'restores the current authenticated user after successful login',
      build: () {
        final repository = AuthMockRepository();
        return AuthBloc(authRepository: repository);
      },
      act: (bloc) async {
        bloc.add(
          const AuthLoginRequested(
            emailOrPhone: 'daily-a@marinelink.demo',
            password: _dailyCredential,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        bloc.add(const AuthCheckRequested());
      },
      wait: const Duration(milliseconds: 1200),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isUser, 'isUser', true),
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isUser, 'isUser', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthFailure] on wrong password',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          emailOrPhone: 'admin@marinelink.demo',
          password: _invalidCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'shows clean text when remote auth throws ApiException with status code',
      build: () => AuthBloc(authRepository: _FailingAuthRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          emailOrPhone: 'daily-a@marinelink.demo',
          password: _invalidCredential,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>()
            .having(
              (state) => state.message,
              'message',
              'Email/số điện thoại hoặc mật khẩu không đúng.',
            )
            .having((state) => state.message, 'message', isNot(contains('401')))
            .having(
              (state) => state.message,
              'message',
              isNot(contains('ApiException')),
            ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthOtpSent] on valid dealer register',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          fullName: 'Nguyen Van B',
          email: 'daily-b@marinelink.demo',
          phone: '0912345000',
          password: _dailyCredential,
          storeName: 'Hai San B',
          businessAddress: 'Can Tho',
          taxCode: '0312345678',
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        const AuthOtpSent(email: 'daily-b@marinelink.demo'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthFailure] when register email already exists',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          fullName: 'MarineLink Admin',
          email: 'admin@marinelink.demo',
          phone: '0900000000',
          password: _adminCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] on logout',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      wait: const Duration(milliseconds: 200),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] for staff login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          emailOrPhone: 'staff@marinelink.demo',
          password: _staffCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isStaff, 'isStaff', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] for user (daily) login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          emailOrPhone: 'daily-a@marinelink.demo',
          password: _dailyCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isUser, 'isUser', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthPasswordChangeSuccess] on successful password change',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthChangePasswordRequested(
          oldPassword: _currentCredential,
          newPassword: _replacementCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), const AuthPasswordChangeSuccess()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthFailure] on password change with wrong old password',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthChangePasswordRequested(
          oldPassword: _invalidOldValue,
          newPassword: _replacementCredential,
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), isA<AuthFailure>()],
    );
  });
}

class _FailingAuthRepository implements AuthRepository {
  @override
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  }) {
    throw const ApiException(
      message: 'INVALID_CREDENTIALS',
      type: ApiExceptionType.unauthorized,
      statusCode: 401,
    );
  }

  @override
  Future<({String token, User user})> loginWithGoogle() =>
      throw UnimplementedError();

  @override
  Future<User> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? storeName,
    String? businessAddress,
    String? taxCode,
  }) => throw UnimplementedError();

  @override
  Future<bool> isEmailAvailable({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isPhoneAvailable({required String phone, String? email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyEmail({required String email, required String otpCode}) =>
      throw UnimplementedError();

  @override
  Future<void> resendOtp({required String email}) => throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<User?> getCurrentUser() => throw UnimplementedError();
}
