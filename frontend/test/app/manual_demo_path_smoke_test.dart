import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/app.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/products/domain/product.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';

void main() {
  setUp(() async {
    BuyerNavigation.resetForTesting();
    await sl.reset();
    await setupServiceLocator();
    AppRouter.router.go(AppRoutes.login);
  });

  tearDown(() async {
    BuyerNavigation.resetForTesting();
    await sl.reset();
  });

  testWidgets(
    'buyer manual demo path reaches products, checkout, orders and chat',
    (tester) async {
      await _pumpApp(tester);
      await _login(
        tester,
        emailOrPhone: 'daily-a@marinelink.demo',
        password: 'Daily@123',
      );

      expect(find.byKey(const Key('homeQuickSearchField')), findsOneWidget);

      final homeContext = tester.element(
        find.byKey(const Key('homeQuickSearchField')),
      );
      GoRouter.of(homeContext).go(AppRoutes.productList);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('productSearchField')), findsOneWidget);

      final productContext = tester.element(
        find.byKey(const Key('productSearchField')),
      );
      productContext.read<CartCubit>().addItem(
        product: _demoProduct(),
        quantity: 2,
      );
      GoRouter.of(productContext).go(AppRoutes.checkout);
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.byKey(const Key('checkoutReceiverNameField')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('checkoutReceiverNameField')),
        'Nguyen Van A',
      );
      await tester.enterText(
        find.byKey(const Key('checkoutReceiverPhoneField')),
        '0912345678',
      );
      await tester.enterText(
        find.byKey(const Key('checkoutShippingAddressField')),
        '123 Tran Hung Dao, Can Tho',
      );

      await tester.ensureVisible(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump(const Duration(milliseconds: 300));
      final submitButton = tester.widget<FilledButton>(
        find.byKey(const Key('checkoutSubmitButton')),
      );
      submitButton.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2600));

      expect(find.byKey(const Key('checkoutSuccessPanel')), findsOneWidget);

      final successContext = tester.element(
        find.byKey(const Key('checkoutSuccessPanel')),
      );
      GoRouter.of(successContext).go(AppRoutes.orders);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('buyerOrderListScreen')), findsOneWidget);

      final ordersContext = tester.element(
        find.byKey(const Key('buyerOrderListScreen')),
      );
      GoRouter.of(ordersContext).go(AppRoutes.home);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('homeQuickSearchField')), findsOneWidget);

      await tester.tap(find.text('Chat').hitTestable().first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
      // Chat tab now opens the chat history list; tapping a room opens the thread.
      expect(find.byKey(const Key('chatRoomsList')), findsOneWidget);
      final roomTile = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('chatRoomTile_'),
      );
      await tester.tap(roomTile.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('chatScreen')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets('admin manual demo path reaches core admin workspaces', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _login(
      tester,
      emailOrPhone: 'admin@marinelink.demo',
      password: 'Admin@123',
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('adminDashboardScreen')), findsOneWidget);
    expect(find.byKey(const Key('adminSystemSummaryBand')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminBottomNavProducts')).hitTestable(),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.byKey(const Key('adminProductsScreen')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminBottomNavUsers')).hitTestable(),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.byKey(const Key('adminUsersScreen')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('adminBottomNavOrders')).hitTestable(),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.byKey(const Key('adminOrderListScreen')), findsOneWidget);
  });

  testWidgets('staff can open product management (stock + add)', (tester) async {
    await _pumpApp(tester);
    await _login(
      tester,
      emailOrPhone: 'staff@marinelink.demo',
      password: 'Staff@123',
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('staffDashboardScreen')), findsOneWidget);

    final staffContext = tester.element(
      find.byKey(const Key('staffDashboardScreen')),
    );
    GoRouter.of(staffContext).go(AppRoutes.staffProducts);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('adminProductsScreen')), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(const MarineLinkApp());
  AppRouter.router.go(AppRoutes.login);
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  required String emailOrPhone,
  required String password,
}) async {
  await tester.enterText(
    find.byKey(const Key('loginEmailOrPhoneField')),
    emailOrPhone,
  );
  await tester.enterText(find.byKey(const Key('loginPasswordField')), password);
  await tester.ensureVisible(find.byKey(const Key('loginSubmitButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('loginSubmitButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

ProductDetail _demoProduct() {
  return const ProductDetail(
    id: 'prod-demo-path-001',
    name: 'Muc kho demo',
    slug: 'muc-kho-demo',
    imageUrl: 'assets/products/dried_squid.png',
    basePrice: 100000,
    unit: 'kg',
    minOrderQuantity: 2,
    stockQuantity: 12,
    status: ProductStatus.active,
    priceTiers: [
      PriceTier(
        id: 'tier-demo-001',
        minQuantity: 2,
        maxQuantity: 4,
        unitPrice: 90000,
      ),
    ],
  );
}
