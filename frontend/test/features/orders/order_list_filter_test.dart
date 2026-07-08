import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/features/orders/presentation/screens/order_list_screen.dart';

Future<void> _pumpStaffOrders(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    const MaterialApp(home: OrderListScreen(staffMode: true)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await sl.reset();
    await setupServiceLocator(useRemoteRepositories: false);
  });
  tearDown(() => sl.reset());

  testWidgets('staff order list shows all orders with a result count', (
    tester,
  ) async {
    await _pumpStaffOrders(tester);

    expect(find.byKey(const Key('staffOrderListScreen')), findsOneWidget);
    expect(find.byKey(const Key('orderListResultCount')), findsOneWidget);
    expect(find.text('5 đơn'), findsOneWidget);
    expect(
      find.byKey(const Key('staffOrderDetailButton_order-001')),
      findsOneWidget,
    );
  });

  testWidgets('filtering by "Đã hủy" narrows the list to cancelled orders', (
    tester,
  ) async {
    await _pumpStaffOrders(tester);

    await tester.ensureVisible(
      find.byKey(const Key('orderFilterChip_CANCELLED')),
    );
    await tester.tap(find.byKey(const Key('orderFilterChip_CANCELLED')));
    await tester.pumpAndSettle();

    expect(find.text('1 đơn'), findsOneWidget);
    expect(
      find.byKey(const Key('staffOrderDetailButton_order-005')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('staffOrderDetailButton_order-001')),
      findsNothing,
    );
  });

  testWidgets('filtering by "Hoàn tất" shows completed orders only', (
    tester,
  ) async {
    await _pumpStaffOrders(tester);

    await tester.ensureVisible(
      find.byKey(const Key('orderFilterChip_COMPLETED')),
    );
    await tester.tap(find.byKey(const Key('orderFilterChip_COMPLETED')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('staffOrderDetailButton_order-004')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('staffOrderDetailButton_order-001')),
      findsNothing,
    );
  });
}
