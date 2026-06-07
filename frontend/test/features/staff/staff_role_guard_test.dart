import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_event.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';
import 'package:marinelink/features/staff/presentation/widgets/staff_role_guard.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

User _user(List<String> roles) => User(
  id: 'user-1',
  fullName: 'Người kiểm thử',
  email: 'test@marinelink.demo',
  phone: '0900000000',
  status: 'ACTIVE',
  roles: roles,
);

void main() {
  late _MockAuthBloc authBloc;

  setUp(() {
    authBloc = _MockAuthBloc();
  });

  Future<void> pumpGuard(WidgetTester tester, AuthState state) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: state,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const StaffRoleGuard(
              child: Scaffold(key: Key('staffGuardedChild')),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, _) =>
              const Scaffold(key: Key('loginRouteStub')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('cho phép STAFF vào khu công việc', (tester) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['STAFF']), token: 't'));

    expect(find.byKey(const Key('staffGuardedChild')), findsOneWidget);
    expect(find.byKey(const Key('staffAccessDeniedScreen')), findsNothing);
  });

  testWidgets('cho phép ADMIN vào khu công việc', (tester) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['ADMIN']), token: 't'));

    expect(find.byKey(const Key('staffGuardedChild')), findsOneWidget);
    expect(find.byKey(const Key('staffAccessDeniedScreen')), findsNothing);
  });

  testWidgets('chặn USER khỏi khu công việc (fallback unauthorized)', (
    tester,
  ) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['USER']), token: 't'));

    expect(find.byKey(const Key('staffGuardedChild')), findsNothing);
    expect(find.byKey(const Key('staffAccessDeniedScreen')), findsOneWidget);
    expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
  });

  testWidgets('chặn khi chưa đăng nhập', (tester) async {
    await pumpGuard(tester, const AuthUnauthenticated());

    expect(find.byKey(const Key('staffGuardedChild')), findsNothing);
    expect(find.byKey(const Key('staffAccessDeniedScreen')), findsOneWidget);
  });

  testWidgets('nút "Đăng nhập lại" điều hướng về /login', (tester) async {
    await pumpGuard(tester, const AuthUnauthenticated());

    await tester.tap(find.text('Đăng nhập lại'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginRouteStub')), findsOneWidget);
  });
}
