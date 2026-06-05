import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/app.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';

void main() {
  setUp(() {
    BuyerNavigation.resetForTesting();
    AppRouter.router.go(AppRoutes.splash);
  });
  tearDown(BuyerNavigation.resetForTesting);

  testWidgets('admin dashboard follows system layout and opens orders', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await sl.reset();
    await setupServiceLocator();
    addTearDown(sl.reset);

    await tester.pumpWidget(const MarineLinkApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('loginEmailOrPhoneField')),
      'admin@marinelink.demo',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'Admin@123',
    );
    await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDashboardScreen')), findsOneWidget);
    expect(find.byKey(const Key('adminSystemSummaryBand')), findsOneWidget);
    expect(find.byKey(const Key('adminOperationsSection')), findsOneWidget);
    expect(find.byKey(const Key('adminUsersShortcut')), findsOneWidget);
    expect(find.byKey(const Key('adminProductsShortcut')), findsOneWidget);
    expect(find.text('Quản lý tài khoản'), findsOneWidget);
    expect(find.text('Giám sát đơn hàng'), findsOneWidget);
    expect(find.byKey(const Key('adminBottomNavDashboard')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('adminRecentOrdersSection')),
      280,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('adminDashboardScreen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('adminRecentOrdersSection')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('adminOrdersShortcut')));

    await tester.tap(find.byKey(const Key('adminOrdersShortcut')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('adminOrderListScreen')), findsOneWidget);
  });

  testWidgets('staff can open work dashboard and update an order status', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await sl.reset();
    await setupServiceLocator();
    addTearDown(sl.reset);

    await tester.pumpWidget(const MarineLinkApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('loginEmailOrPhoneField')),
      'staff@marinelink.demo',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'Staff@123',
    );
    await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staffDashboardScreen')), findsOneWidget);
    expect(find.byKey(const Key('staffWorkOverviewSection')), findsOneWidget);
    expect(find.byKey(const Key('staffWaitingChatCard')), findsOneWidget);
    expect(find.byKey(const Key('staffQuickActionsSection')), findsOneWidget);
    expect(find.byKey(const Key('staffSupportChatSection')), findsOneWidget);
    expect(find.byKey(const Key('staffBottomNavWork')), findsOneWidget);
    expect(find.text('Quản lý công việc'), findsOneWidget);
    expect(find.text('Đơn cần xử lý'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('staffDeliveryRouteSection')),
      320,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('staffDashboardScreen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('staffDeliveryRouteSection')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('staffOrdersShortcut')));

    await tester.tap(find.byKey(const Key('staffOrdersShortcut')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('staffOrderListScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('staffOrderDetailButton_order-001')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('staffOrderDetailScreen')), findsOneWidget);
    expect(find.byKey(const Key('staffOrderStatusPanel')), findsOneWidget);
    expect(
      find.byKey(const Key('staffOrderStatusOption_CONFIRMED')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('staffOrderStatusOption_CONFIRMED')));
    await tester.enterText(
      find.byKey(const Key('staffOrderStatusNoteField')),
      'Da xac nhan don',
    );
    await tester.ensureVisible(
      find.byKey(const Key('staffOrderStatusSubmitButton')),
    );
    await tester.tap(find.byKey(const Key('staffOrderStatusSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(
      find.byKey(const Key('staffOrderStatusOption_SHIPPING')),
      findsOneWidget,
    );
  });

  testWidgets('buyer role cannot see admin dashboard content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await sl.reset();
    await setupServiceLocator();
    addTearDown(sl.reset);

    await tester.pumpWidget(const MarineLinkApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('loginEmailOrPhoneField')),
      'daily-a@marinelink.demo',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'Daily@123',
    );
    await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminDashboardScreen')), findsNothing);
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });
}
