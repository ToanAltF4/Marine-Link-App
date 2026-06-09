import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/auth/data/auth_mock_repository.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_event.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';

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
          password: 'Daily@123',
        ).props,
        ['daily-a@marinelink.demo'],
      );
      expect(
        const AuthRegisterRequested(
          fullName: 'Nguyen Van A',
          email: 'daily-new@example.com',
          phone: '0912345678',
          password: 'Daily@123',
        ).props,
        ['daily-new@example.com', '0912345678'],
      );
      expect(const AuthCheckRequested().props, isEmpty);
      expect(const AuthLogoutRequested().props, isEmpty);
      expect(
        const AuthChangePasswordRequested(
          oldPassword: 'old',
          newPassword: 'new',
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
          password: 'Admin@123',
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.user.isAdmin, 'isAdmin', true),
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
            password: 'Daily@123',
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
          password: 'wrong-password',
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [const AuthLoading(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthOtpSent] on valid dealer register',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthRegisterRequested(
          fullName: 'Nguyen Van B',
          email: 'daily-b@marinelink.demo',
          phone: '0912345000',
          password: 'Daily@123',
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
          password: 'Admin@123',
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
          password: 'Staff@123',
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
          password: 'Daily@123',
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
          oldPassword: 'correct',
          newPassword: 'new-password',
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        const AuthPasswordChangeSuccess(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthFailure] on password change with wrong old password',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(
        const AuthChangePasswordRequested(
          oldPassword: 'wrong',
          newPassword: 'new-password',
        ),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>(),
      ],
    );
  });
}
