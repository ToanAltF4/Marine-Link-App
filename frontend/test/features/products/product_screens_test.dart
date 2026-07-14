import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/home/presentation/screens/home_screen.dart';
import 'package:marinelink/features/products/data/product_mock_repository.dart';
import 'package:marinelink/features/products/presentation/screens/product_detail_screen.dart';
import 'package:marinelink/features/products/presentation/screens/product_list_screen.dart';
import 'package:marinelink/shared/navigation/app_back_exit_controller.dart';
import 'package:marinelink/shared/widgets/buyer_back_to_home_scope.dart';
import 'package:marinelink/shared/widgets/buyer_bottom_nav.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    AppBackExitController.resetForTesting();
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(AppBackExitController.resetForTesting);

  group('HomeScreen', () {
    testWidgets('shows bulk discount promotion copy matching cart policy', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: HomeScreen(productRepository: ProductMockRepository()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ưu đãi mua nhiều'), findsOneWidget);
      expect(find.text('Giảm đến 8% cho đơn hàng từ 500kg'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(
          '50-99kg giảm 2% • 100-199kg giảm 4% • 200-499kg giảm 6% • ≥ 500kg giảm 8%',
        ),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          '50-99kg giảm 2% • 100-199kg giảm 4% • 200-499kg giảm 6% • ≥ 500kg giảm 8%',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('5 sản phẩm'), findsNothing);
      expect(find.textContaining('10 sản phẩm'), findsNothing);
    });

    testWidgets('hides menu icon and keeps featured cards compact on phones', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: HomeScreen(productRepository: ProductMockRepository()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.menu_rounded), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('featuredProductCard-prod-001')),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      final cardSize = tester.getSize(
        find.byKey(const Key('featuredProductCard-prod-001')),
      );
      expect(cardSize.height, lessThanOrEqualTo(210));
    });

    testWidgets('caps featured card width on wider phone viewports', (
      tester,
    ) async {
      const viewportWidth = 469.0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(viewportWidth, 932);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: HomeScreen(productRepository: ProductMockRepository()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.scrollUntilVisible(
        find.byKey(const Key('featuredProductCard-prod-001')),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      final cardSize = tester.getSize(
        find.byKey(const Key('featuredProductCard-prod-001')),
      );
      expect(cardSize.width, lessThanOrEqualTo(168));
      expect(cardSize.height, lessThanOrEqualTo(210));

      final firstCardRect = tester.getRect(
        find.byKey(const Key('featuredProductCard-prod-001')),
      );
      final secondCardRect = tester.getRect(
        find.byKey(const Key('featuredProductCard-prod-002')),
      );
      expect(secondCardRect.left - firstCardRect.right, closeTo(12, 0.1));
      expect(
        firstCardRect.left,
        closeTo(viewportWidth - secondCardRect.right, 1),
      );
    });

    testWidgets('shows featured products and forwards quick search', (
      tester,
    ) async {
      String? capturedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: HomeScreen(
              productRepository: ProductMockRepository(),
              onQuickSearch: (query) => capturedQuery = query,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('homeQuickSearchField')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('homeQuickSearchField')),
        'tom kho',
      );
      await tester.tap(find.byKey(const Key('homeQuickSearchButton')));
      await tester.pump();
      expect(capturedQuery, 'tom kho');

      await tester.scrollUntilVisible(
        find.byKey(const Key('featuredProductCard-prod-001')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('featuredProductCard-prod-001')),
        findsOneWidget,
      );
    });
  });

  group('ProductListScreen', () {
    testWidgets('system back returns to home from the product tab', (
      tester,
    ) async {
      final platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            platformCalls.add(call);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final repository = ProductMockRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                HomeScreen(productRepository: repository),
          ),
          GoRoute(
            path: AppRoutes.productList,
            builder: (context, state) =>
                ProductListScreen(productRepository: repository),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (context, state) => const _CartRouteProbe(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('homeQuickSearchField')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.sailing_outlined));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('productSearchField')), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('homeQuickSearchField')), findsOneWidget);
      expect(find.byKey(const Key('productSearchField')), findsNothing);
      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty,
      );

      final secondHandled = await tester.binding.handlePopRoute();
      expect(secondHandled, isTrue);
      await tester.pump();

      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty,
      );

      // Lần 2 nhấn back trong 800ms → double-back thoát app
      final thirdHandled = await tester.binding.handlePopRoute();
      expect(thirdHandled, isTrue);
      await tester.pump();

      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isNotEmpty,
      );
    });

    testWidgets('back from cart restores the previous product list state', (
      tester,
    ) async {
      final repository = ProductMockRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                HomeScreen(productRepository: repository),
          ),
          GoRoute(
            path: AppRoutes.productList,
            builder: (context, state) =>
                ProductListScreen(productRepository: repository),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (context, state) => const _CartRouteProbe(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.sailing_outlined));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(ProductListScreen.productListScrollKey),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      final offsetBeforeCart = _productListScrollOffset(tester);

      await tester.enterText(
        find.byKey(const Key('productSearchField')),
        'tom',
      );
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cartRouteProbe')), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('productSearchField')), findsOneWidget);
      final searchField = tester.widget<TextField>(
        find.byKey(const Key('productSearchField')),
      );
      expect(searchField.controller?.text, 'tom');
      expect(_productListScrollOffset(tester), offsetBeforeCart);
    });

    testWidgets('supports search and empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('productCard-prod-001')), findsOneWidget);
      expect(
        find.text(
          'Size lon, kho deu mau, phu hop dai ly can nguon hang on dinh.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('productSearchField')),
        'khong ton tai',
      );
      await tester.tap(find.byKey(const Key('productSearchButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('productListEmptyState')), findsOneWidget);
    });

    testWidgets('uses parent category filters before child filters', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // No category selected yet — filter button shows 0
      expect(find.text('Lọc (0)'), findsOneWidget);

      // Open filter sheet and select parent category 'Cá'
      await tester.tap(find.byKey(const Key('productAdvancedFilterButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('productFilterSheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('productFilterCategory-cat-fish')));
      await tester.pump();

      // Child row appears inside sheet
      expect(find.text('Tất cả cá'), findsOneWidget);
      expect(find.text('Cá khô'), findsWidgets);
      expect(find.text('Cá đông lạnh'), findsOneWidget);

      // Select child 'Cá khô'
      await tester.tap(find.text('Cá khô').first);
      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      // Active chips show the selected category name; badge = 1
      expect(find.text('Lọc (1)'), findsOneWidget);
      expect(find.byKey(const Key('productCard-prod-003')), findsOneWidget);

      // Open sheet again, switch to 'Mực'
      await tester.tap(find.byKey(const Key('productAdvancedFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('productFilterCategory-cat-squid')),
      );
      await tester.pump();

      expect(find.text('Tất cả mực'), findsOneWidget);
      expect(find.text('Mực khô'), findsWidgets);
      expect(find.text('Mực đông lạnh'), findsOneWidget);

      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('productCard-prod-001')), findsOneWidget);
    });

    testWidgets('keeps category navigation separate from filter button', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final advanced = find.byKey(const Key('productAdvancedFilterButton'));
      final productList = find.byKey(ProductListScreen.productListScrollKey);

      // Filter button is present; no active chips initially
      expect(advanced, findsOneWidget);
      expect(productList, findsOneWidget);
      expect(find.text('Lọc (0)'), findsOneWidget);
      expect(find.text('Còn hàng'), findsNothing);
      expect(find.text('Sắp hết'), findsNothing);
      expect(find.text('Giá tăng dần'), findsNothing);

      // Product list sits below the header bar
      final headerBar = find.byType(Material).first;
      expect(
        tester.getRect(productList).top,
        greaterThan(tester.getRect(headerBar).top),
      );

      // After applying a filter, active chip appears left of filter button
      await tester.tap(advanced);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('productFilterStockAvailable')));
      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc (1)'), findsOneWidget);
      expect(find.text('Còn hàng'), findsOneWidget);
      // Active chip is to the left of the filter button
      expect(
        tester.getRect(find.text('Còn hàng').first).right,
        lessThanOrEqualTo(tester.getRect(advanced).left + 4),
      );
    });

    testWidgets('filter strip is hard-clipped with clamping scroll physics', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final advanced = find.byKey(const Key('productAdvancedFilterButton'));

      // Filter button is present and on-screen
      expect(advanced, findsOneWidget);
      expect(tester.getRect(advanced).right, lessThanOrEqualTo(393));

      // Apply a filter so the active chip scrollable appears
      await tester.tap(advanced);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('productFilterSortPriceAsc')));
      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc (1)'), findsOneWidget);

      // The active chip scrollable sits left of the filter button
      final scrollable = find.byKey(const Key('productScrollableFilters'));
      expect(scrollable, findsOneWidget);
      expect(
        tester.getRect(scrollable).right,
        lessThanOrEqualTo(tester.getRect(advanced).left + 4),
      );

      // Filter button stays within screen width after drag
      await tester.drag(scrollable, const Offset(-260, 0));
      await tester.pump();
      expect(tester.getRect(advanced).right, lessThanOrEqualTo(393));
    });

    testWidgets('applies stock filter from the product filter sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('productCard-prod-001')), findsOneWidget);

      await tester.tap(find.byKey(const Key('productAdvancedFilterButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('productFilterSheet')), findsOneWidget);
      expect(
        find.byKey(const Key('productFilterPriceUnder300')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('productFilterOriginAll')), findsOneWidget);
      expect(find.byKey(const Key('productFilterSortDefault')), findsOneWidget);
      await tester.tap(find.byKey(const Key('productFilterStockLow')));
      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc (1)'), findsOneWidget);
      expect(find.text('2 mặt hàng'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('productCard-prod-004')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('productCard-prod-004')), findsOneWidget);
      // 'Sắp hết' now also shows as an active filter chip in the bar
      expect(find.text('Sắp hết'), findsOneWidget);

      await tester.tap(find.byKey(const Key('productAdvancedFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('productFilterResetButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('productCard-prod-001')), findsOneWidget);
      expect(find.text('Lọc (0)'), findsOneWidget);
    });

    testWidgets('applies price and origin filters from the sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('productAdvancedFilterButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('productFilterPriceUnder300')));
      await tester.ensureVisible(
        find.byKey(const Key('productFilterOrigin-Phu Quoc')),
      );
      await tester.tap(find.byKey(const Key('productFilterOrigin-Phu Quoc')));
      await tester.tap(find.byKey(const Key('productFilterApplyButton')));
      await tester.pumpAndSettle();

      expect(find.text('Lọc (2)'), findsOneWidget);
      expect(find.byKey(const Key('productCard-prod-007')), findsOneWidget);
      expect(find.byKey(const Key('productCard-prod-003')), findsNothing);
    });
  });

  group('ProductDetailScreen', () {
    testWidgets('renders the reference product detail layout', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => CartCubit()),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductDetailScreen(
              productId: 'prod-001',
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('productDetailLogo')), findsOneWidget);
      final detailTitle = tester.widget<Text>(
        find.byKey(const Key('productDetailLogo')),
      );
      expect(detailTitle.style?.fontFamily, 'serif');
      expect(find.byKey(const Key('productDetailHeroImage')), findsOneWidget);
      expect(
        find.byKey(const Key('productDetailWholesaleCard')),
        findsOneWidget,
      );
      expect(find.text('M\u1ef1c kh\u00f4 lo\u1ea1i 1'), findsOneWidget);
      expect(find.text('Gi\u00e1 s\u1ec9 t\u1eeb:'), findsOneWidget);
      expect(find.text('450.000\u0111/kg'), findsWidgets);
      expect(find.text('B\u1ea3ng gi\u00e1 s\u1ec9'), findsOneWidget);
      expect(
        find.byKey(const Key('productDetailPackagingSpec')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('productDetailBottomNav')), findsOneWidget);

      final heroRect = tester.getRect(
        find.byKey(const Key('productDetailHeroImage')),
      );
      final cardRect = tester.getRect(
        find.byKey(const Key('productDetailWholesaleCard')),
      );
      final navRect = tester.getRect(
        find.byKey(const Key('productDetailBottomNav')),
      );

      expect(heroRect.top, greaterThanOrEqualTo(56));
      expect(cardRect.top, greaterThan(heroRect.bottom));
      expect(navRect.bottom, closeTo(844, 1));
    });

    testWidgets('shows fixed wholesale discount tiers and adds item to cart', (
      tester,
    ) async {
      final cartCubit = CartCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cartCubit),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductDetailScreen(
              productId: 'prod-001',
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.scrollUntilVisible(
        find.byKey(const Key('priceTier-bulk-50-99')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('priceTier-bulk-50-99')), findsOneWidget);
      expect(find.text('50 - 99 kg'), findsOneWidget);
      expect(find.text('441.000\u0111/kg'), findsOneWidget);
      expect(find.text('(-2%)'), findsOneWidget);
      expect(find.text('100 - 199 kg'), findsOneWidget);
      expect(find.text('432.000\u0111/kg'), findsOneWidget);
      expect(find.text('(-4%)'), findsOneWidget);
      expect(find.text('200 - 499 kg'), findsOneWidget);
      expect(find.text('423.000\u0111/kg'), findsOneWidget);
      expect(find.text('(-6%)'), findsOneWidget);
      expect(find.text('500 kg+'), findsOneWidget);
      expect(find.text('414.000\u0111/kg'), findsOneWidget);
      expect(find.text('(-8%)'), findsOneWidget);
      expect(find.text('(-5%)'), findsNothing);
      expect(find.text('(-10%)'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('addToCartButton')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('addToCartButton')));
      await tester.pump();

      expect(cartCubit.state.cart.items, hasLength(1));
      expect(cartCubit.state.cart.items.single.productId, 'prod-001');
    });

    testWidgets('allows entering quantity before adding to cart', (
      tester,
    ) async {
      final cartCubit = CartCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cartCubit),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductDetailScreen(
              productId: 'prod-001',
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.scrollUntilVisible(
        find.byKey(const Key('productDetailQuantityInput')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final quantityTextField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('productDetailQuantityInput')),
          matching: find.byType(TextField),
        ),
      );
      final quantityFrame = tester.widget<DecoratedBox>(
        find.byKey(const Key('productDetailQuantityInputFrame')),
      );
      final frameDecoration = quantityFrame.decoration as BoxDecoration;
      final quantityFrameRect = tester.getRect(
        find.byKey(const Key('productDetailQuantityInputFrame')),
      );
      final decreaseButtonRect = tester.getRect(
        find.byKey(const Key('productDetailDecreaseButton')),
      );
      final increaseButtonRect = tester.getRect(
        find.byKey(const Key('productDetailIncreaseButton')),
      );
      expect(frameDecoration.border, isA<Border>());
      expect(quantityTextField.decoration?.border, InputBorder.none);
      expect(quantityTextField.decoration?.focusedBorder, InputBorder.none);
      expect(
        decreaseButtonRect.center.dy,
        closeTo(quantityFrameRect.center.dy, 1),
      );
      expect(
        increaseButtonRect.center.dy,
        closeTo(quantityFrameRect.center.dy, 1),
      );
      await tester.enterText(
        find.byKey(const Key('productDetailQuantityInput')),
        '50',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(find.byKey(const Key('addToCartButton')));
      await tester.pump();

      expect(cartCubit.state.cart.items.single.quantity, 50);
    });

    testWidgets('uses typed quantity for add and stepper actions', (
      tester,
    ) async {
      final cartCubit = CartCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cartCubit),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: ProductDetailScreen(
              productId: 'prod-001',
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.scrollUntilVisible(
        find.byKey(const Key('productDetailQuantityInput')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('productDetailQuantityInput')),
        '50',
      );
      await tester.tap(find.byKey(const Key('productDetailIncreaseButton')));
      await tester.pump();

      expect(_productDetailQuantityText(tester), '51');

      await tester.tap(find.byKey(const Key('productDetailDecreaseButton')));
      await tester.pump();

      expect(_productDetailQuantityText(tester), '50');

      await tester.tap(find.byKey(const Key('addToCartButton')));
      await tester.pump();

      expect(cartCubit.state.cart.items.single.quantity, 50);
    });
  });
}

double _productListScrollOffset(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byKey(ProductListScreen.productListScrollKey),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

String _productDetailQuantityText(WidgetTester tester) {
  final quantityTextField = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(const Key('productDetailQuantityInput')),
      matching: find.byType(TextField),
    ),
  );
  return quantityTextField.controller?.text ?? '';
}

class _CartRouteProbe extends StatelessWidget {
  const _CartRouteProbe();

  @override
  Widget build(BuildContext context) {
    return const BuyerBackToHomeScope(
      child: Scaffold(
        body: Center(child: Text('Cart route', key: Key('cartRouteProbe'))),
        bottomNavigationBar: BuyerBottomNav(currentTab: BuyerBottomNavTab.cart),
      ),
    );
  }
}
