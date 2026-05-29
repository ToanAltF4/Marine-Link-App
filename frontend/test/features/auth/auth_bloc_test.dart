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
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when check requested with no session',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful admin login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        emailOrPhone: 'admin@marinelink.demo',
        password: 'Admin@123',
      )),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.isAdmin,
          'isAdmin',
          true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthFailure] on wrong password',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        emailOrPhone: 'admin@marinelink.demo',
        password: 'wrong-password',
      )),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] on logout',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] for staff login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        emailOrPhone: 'staff@marinelink.demo',
        password: 'Staff@123',
      )),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.isStaff,
          'isStaff',
          true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] for user (daily) login',
      build: () => AuthBloc(authRepository: AuthMockRepository()),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        emailOrPhone: 'daily-a@marinelink.demo',
        password: 'Daily@123',
      )),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.isUser,
          'isUser',
          true,
        ),
      ],
    );
  });
}
