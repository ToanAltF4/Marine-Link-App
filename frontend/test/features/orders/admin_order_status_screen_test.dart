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

  testWidgets('staff can open admin orders and update an order status', (
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

    expect(find.byKey(const Key('adminDashboardScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminOrdersShortcut')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('adminOrderListScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminOrderDetailButton_order-001')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('adminOrderStatusPanel')), findsOneWidget);
    expect(
      find.byKey(const Key('adminOrderStatusOption_CONFIRMED')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('adminOrderStatusOption_CONFIRMED')));
    await tester.enterText(
      find.byKey(const Key('adminOrderStatusNoteField')),
      'Da xac nhan don',
    );
    await tester.ensureVisible(
      find.byKey(const Key('adminOrderStatusSubmitButton')),
    );
    await tester.tap(find.byKey(const Key('adminOrderStatusSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(
      find.byKey(const Key('adminOrderStatusOption_SHIPPING')),
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
