import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/products/data/product_mock_repository.dart';
import 'package:marinelink/features/products/presentation/screens/product_detail_screen.dart';
import 'package:marinelink/features/products/presentation/screens/product_list_screen.dart';
import 'package:marinelink/features/home/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows featured products and forwards quick search', (
      tester,
    ) async {
      String? capturedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => CartCubit(),
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
    testWidgets('supports search and empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => CartCubit(),
            child: ProductListScreen(
              productRepository: ProductMockRepository(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('productCard-prod-001')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('productSearchField')),
        'khong ton tai',
      );
      await tester.tap(find.byKey(const Key('productSearchButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('productListEmptyState')), findsOneWidget);
    });
  });

  group('ProductDetailScreen', () {
    testWidgets('shows price tiers and adds item to cart', (tester) async {
      final cartCubit = CartCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cartCubit,
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
        find.byKey(const Key('priceTier-tier-001-a')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('priceTier-tier-001-a')), findsOneWidget);

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
  });
}
