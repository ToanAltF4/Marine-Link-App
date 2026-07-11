import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/features/auth/data/auth_mock_repository.dart';
import 'package:marinelink/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:marinelink/features/auth/presentation/screens/reset_password_screen.dart';

const _email = 'daily-a@marinelink.demo';

Widget _wrap(Widget child, {String initialLocation = '/'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, _) => child),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => Scaffold(
          key: const Key('resetStub'),
          body: Text('Reset Stub: ${state.extra}'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => const Scaffold(body: Text('Login Stub')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('renders email field and send button', (tester) async {
      await tester.pumpWidget(
        _wrap(ForgotPasswordScreen(authRepository: AuthMockRepository())),
      );

      expect(find.byKey(const Key('forgotPasswordEmailField')), findsOneWidget);
      expect(
        find.byKey(const Key('forgotPasswordSubmitButton')),
        findsOneWidget,
      );
    });

    testWidgets('blocks submit and shows error for invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ForgotPasswordScreen(authRepository: AuthMockRepository())),
      );

      await tester.enterText(
        find.byKey(const Key('forgotPasswordEmailField')),
        'bad-email',
      );
      final button = find.byKey(const Key('forgotPasswordSubmitButton'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.byKey(const Key('resetStub')), findsNothing);
    });

    testWidgets('navigates to reset screen with email on OTP request', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ForgotPasswordScreen(authRepository: AuthMockRepository())),
      );

      await tester.enterText(
        find.byKey(const Key('forgotPasswordEmailField')),
        _email,
      );
      final button = find.byKey(const Key('forgotPasswordSubmitButton'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.byKey(const Key('forgotPasswordLoading')), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.byKey(const Key('resetStub')), findsOneWidget);
      expect(find.text('Reset Stub: $_email'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('shows mismatch error when confirm password differs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ResetPasswordScreen(
            email: _email,
            authRepository: AuthMockRepository(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('resetPasswordOtpField')),
        '123456',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordNewField')),
        'newpass123',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordConfirmField')),
        'different123',
      );
      final button = find.byKey(const Key('resetPasswordSubmitButton'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
      // No navigation away from the reset screen.
      expect(find.text('Login Stub'), findsNothing);
    });

    testWidgets('shows error snackbar when OTP is invalid', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResetPasswordScreen(
            email: _email,
            authRepository: AuthMockRepository(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('resetPasswordOtpField')),
        '000000',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordNewField')),
        'newpass123',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordConfirmField')),
        'newpass123',
      );
      final button = find.byKey(const Key('resetPasswordSubmitButton'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.byKey(const Key('resetPasswordError')), findsOneWidget);
      expect(
        find.text('Mã OTP không tồn tại hoặc đã được sử dụng'),
        findsOneWidget,
      );
    });

    testWidgets('resets password and returns to login on success', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ResetPasswordScreen(
            email: _email,
            authRepository: AuthMockRepository(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('resetPasswordOtpField')),
        '123456',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordNewField')),
        'newpass123',
      );
      await tester.enterText(
        find.byKey(const Key('resetPasswordConfirmField')),
        'newpass123',
      );
      final button = find.byKey(const Key('resetPasswordSubmitButton'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(find.byKey(const Key('resetPasswordLoading')), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.text('Login Stub'), findsOneWidget);
    });
  });
}
