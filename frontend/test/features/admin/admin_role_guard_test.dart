import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/features/admin/presentation/widgets/admin_role_guard.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_event.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';

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

  // Bơm guard vào một GoRouter tối thiểu để nút "Đăng nhập lại" (context.go)
  // hoạt động được trong widget test.
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
            child: const AdminRoleGuard(
              child: Scaffold(key: Key('adminGuardedChild')),
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

  testWidgets('cho phép ADMIN vào khu quản trị', (tester) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['ADMIN']), token: 't'));

    expect(find.byKey(const Key('adminGuardedChild')), findsOneWidget);
    expect(find.byKey(const Key('adminAccessDeniedScreen')), findsNothing);
  });

  testWidgets('chặn STAFF khỏi khu quản trị (fallback unauthorized)', (
    tester,
  ) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['STAFF']), token: 't'));

    expect(find.byKey(const Key('adminGuardedChild')), findsNothing);
    expect(find.byKey(const Key('adminAccessDeniedScreen')), findsOneWidget);
    expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
  });

  testWidgets('chặn USER khỏi khu quản trị', (tester) async {
    await pumpGuard(tester, AuthAuthenticated(user: _user(['USER']), token: 't'));

    expect(find.byKey(const Key('adminGuardedChild')), findsNothing);
    expect(find.byKey(const Key('adminAccessDeniedScreen')), findsOneWidget);
  });

  testWidgets('chặn khi chưa đăng nhập', (tester) async {
    await pumpGuard(tester, const AuthUnauthenticated());

    expect(find.byKey(const Key('adminGuardedChild')), findsNothing);
    expect(find.byKey(const Key('adminAccessDeniedScreen')), findsOneWidget);
  });

  testWidgets('nút "Đăng nhập lại" điều hướng về /login', (tester) async {
    await pumpGuard(tester, const AuthUnauthenticated());

    await tester.tap(find.byKey(const Key('adminAccessLoginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginRouteStub')), findsOneWidget);
  });
}
