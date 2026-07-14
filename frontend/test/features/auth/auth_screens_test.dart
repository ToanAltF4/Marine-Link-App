import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/features/auth/data/auth_mock_repository.dart';
import 'package:marinelink/features/auth/domain/auth_repository.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/screens/login_screen.dart';
import 'package:marinelink/features/auth/presentation/screens/register_screen.dart';

Widget _wrap(Widget child) {
  final authRepository = AuthMockRepository();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository),
          child: _withRepository(child, authRepository),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => Scaffold(
          key: const Key('verifyEmailStub'),
          body: Text('Verify Email Stub: ${state.extra}'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => const Scaffold(body: Text('Login Stub')),
      ),
      GoRoute(
        path: '/home',
        builder: (context, _) => const Scaffold(body: Text('Home Stub')),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => const Scaffold(body: Text('Admin Stub')),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, _) => const Scaffold(body: Text('Staff Stub')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Widget _withRepository(Widget child, AuthRepository repository) {
  if (child is RegisterScreen) {
    return RegisterScreen(authRepository: repository);
  }
  return child;
}

void main() {
  group('LoginScreen', () {
    testWidgets('does not show red errors before fields are dirty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Email hoặc số điện thoại không được để trống'),
        findsNothing,
      );
      expect(find.text('Mật khẩu không được để trống'), findsNothing);
      expect(_loginSubmitButton(tester).onPressed, isNull);
    });

    testWidgets('validates dirty login fields inline', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.enterText(
        find.byKey(const Key('loginEmailOrPhoneField')),
        'bad-email',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        '123',
      );
      await tester.pump();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsWidgets);
      expect(_loginSubmitButton(tester).onPressed, isNull);
    });

    testWidgets('submits demo user credentials through AuthBloc', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      await tester.enterText(
        find.byKey(const Key('loginEmailOrPhoneField')),
        'daily-a@marinelink.demo',
      );
      await tester.enterText(
        find.byKey(const Key('loginPasswordField')),
        'Daily@123',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loginSubmitButton')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      expect(find.textContaining('Đăng nhập thành công'), findsOneWidget);
    });

    testWidgets('Google button signs in through AuthBloc and routes home', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      final googleButton = find.byKey(const Key('loginGoogleButton'));
      await tester.ensureVisible(googleButton);
      await tester.pumpAndSettle();
      await tester.tap(googleButton);
      await tester.pump();

      // Mock Google sign-in resolves to a USER → routed to the home stub.
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      expect(find.text('Home Stub'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('renders dealer registration fields', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      expect(find.byKey(const Key('registerFullNameField')), findsOneWidget);
      expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
      expect(find.byKey(const Key('registerPhoneField')), findsOneWidget);
      expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('registerTaxCodeField')), findsOneWidget);
    });

    testWidgets('submits valid dealer registration through AuthBloc', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      await tester.enterText(
        find.byKey(const Key('registerFullNameField')),
        'Nguyen Van B',
      );
      await tester.enterText(
        find.byKey(const Key('registerEmailField')),
        'daily-b@marinelink.demo',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      await tester.enterText(
        find.byKey(const Key('registerPhoneField')),
        '0912345000',
      );
      await tester.enterText(
        find.byKey(const Key('registerPasswordField')),
        'Daily@123',
      );
      await tester.enterText(
        find.byKey(const Key('registerConfirmPasswordField')),
        'Daily@123',
      );
      await tester.enterText(
        find.byKey(const Key('registerBusinessAddressField')),
        '123 Tran Hung Dao, Can Tho',
      );
      await tester.enterText(
        find.byKey(const Key('registerTaxCodeField')),
        '0312345678',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.byKey(const Key('registerSubmitButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('registerSubmitButton')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('verifyEmailStub')), findsOneWidget);
    });

    testWidgets('checks duplicate email with debounce before submit', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      await tester.enterText(
        find.byKey(const Key('registerEmailField')),
        'admin@marinelink.demo',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.text('Email đã được sử dụng.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_registerSubmitButton(tester).onPressed, isNull);
    });

    testWidgets('checks duplicate phone with debounce before submit', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      await tester.enterText(
        find.byKey(const Key('registerEmailField')),
        'daily-new@marinelink.demo',
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 700));
      await tester.enterText(
        find.byKey(const Key('registerPhoneField')),
        '0900000000',
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.text('Số điện thoại đã được sử dụng.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_registerSubmitButton(tester).onPressed, isNull);
    });
  });
}

FilledButton _loginSubmitButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const Key('loginSubmitButton')),
      matching: find.byType(FilledButton),
    ),
  );
}

FilledButton _registerSubmitButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.byKey(const Key('registerSubmitButton')),
  );
}
