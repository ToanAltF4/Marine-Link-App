import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/profile/presentation/screens/profile_screen.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';

void main() {
  setUp(BuyerNavigation.resetForTesting);
  tearDown(BuyerNavigation.resetForTesting);

  testWidgets('opens orders from the profile page', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) =>
              const Scaffold(body: Text('Orders route probe')),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) =>
              const Scaffold(body: Text('Chat route probe')),
        ),
        GoRoute(
          path: AppRoutes.cart,
          builder: (context, state) =>
              const Scaffold(body: Text('Cart route probe')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(body: Text('Home route probe')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );

    expect(find.text('Tài khoản'), findsWidgets);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Giỏ hàng'), findsOneWidget);

    await tester.tap(find.text('Đơn hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Orders route probe'), findsOneWidget);
  });
}
