import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/cart/presentation/screens/cart_screen.dart';
import 'package:marinelink/features/products/domain/product.dart';

void main() {
  group('CartScreen', () {
    testWidgets('shows empty state and keeps checkout disabled', (
      tester,
    ) async {
      var continueShoppingTapped = false;

      await tester.pumpWidget(
        _wrap(
          cartCubit: CartCubit(),
          onContinueShopping: () => continueShoppingTapped = true,
        ),
      );

      expect(find.text('Gi\u1ecf h\u00e0ng c\u1ee7a b\u1ea1n'), findsOneWidget);
      expect(
        find.text('Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng'),
        findsOneWidget,
      );
      expect(find.text('T\u1ed5ng \u0111\u01a1n h\u00e0ng'), findsOneWidget);
      expect(
        find.text('Ti\u1ebfn h\u00e0nh \u0111\u1eb7t h\u00e0ng'),
        findsOneWidget,
      );

      final checkoutButton = tester.widget<FilledButton>(
        find.byKey(const Key('cartCheckoutButton')),
      );
      expect(checkoutButton.onPressed, isNull);

      await tester.tap(find.text('Ch\u1ecdn s\u1ea3n ph\u1ea9m'));
      expect(continueShoppingTapped, isTrue);
    });

    testWidgets('updates quantity totals and removes item', (tester) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(_wrap(cartCubit: cartCubit));

      expect(find.text('Gi\u1ecf h\u00e0ng c\u1ee7a b\u1ea1n'), findsOneWidget);
      expect(find.text('M\u1ef1c kh\u00f4 lo\u1ea1i 1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      final imageRect = tester.getRect(find.byType(Image));
      final thumbnailRect = tester.getRect(
        find.byKey(const Key('cartProductThumbnail-prod-001')),
      );
      final thumbnailClip = tester.widget<ClipRRect>(
        find.byKey(const Key('cartProductThumbnail-prod-001')),
      );
      final titleRect = tester.getRect(
        find.text('M\u1ef1c kh\u00f4 lo\u1ea1i 1'),
      );
      expect(thumbnailClip.borderRadius, BorderRadius.circular(18));
      expect(titleRect.left, greaterThan(thumbnailRect.right));
      expect(titleRect.top, greaterThanOrEqualTo(thumbnailRect.top));
      expect(titleRect.top, lessThan(thumbnailRect.bottom));
      expect(imageRect.left, greaterThan(thumbnailRect.left));
      expect(imageRect.top, greaterThan(thumbnailRect.top));
      expect(imageRect.right, lessThan(thumbnailRect.right));
      expect(imageRect.bottom, lessThan(thumbnailRect.bottom));
      final productImage = tester.widget<Image>(find.byType(Image));
      expect(productImage.fit, BoxFit.cover);
      final itemTapTarget = tester.widget<InkWell>(
        find.byKey(const Key('cartSelectedToggle-prod-001')),
      );
      expect(itemTapTarget.borderRadius, BorderRadius.circular(18));
      final imageClip = tester.widget<ClipRRect>(
        find.byKey(const Key('cartProductImageClip-prod-001')),
      );
      expect(imageClip.borderRadius, BorderRadius.circular(16));
      final imageSurface = tester.widget<Container>(
        find.byKey(const Key('cartProductImageSurface-prod-001')),
      );
      final imageSurfaceDecoration = imageSurface.decoration as BoxDecoration;
      expect(imageSurfaceDecoration.borderRadius, BorderRadius.circular(16));
      expect(imageSurface.clipBehavior, Clip.antiAlias);
      expect(
        find.byWidgetPredicate(_isSystemSurfaceCard),
        findsAtLeastNWidgets(2),
      );
      expect(cartCubit.state.subtotalAmount, 180000);
      expect(find.text('T\u1ed5ng \u0111\u01a1n h\u00e0ng'), findsOneWidget);
      expect(find.text('Khuyến mãi mua nhiều:'), findsOneWidget);
      expect(find.text('Chưa áp dụng'), findsOneWidget);
      expect(find.text('Mi\u1ec5n ph\u00ed'), findsOneWidget);
      expect(find.text('180.000\u0111'), findsWidgets);

      await tester.tap(find.byKey(const Key('cartIncreaseButton-prod-001')));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(cartCubit.state.subtotalAmount, 270000);

      await tester.tap(find.byKey(const Key('cartDecreaseButton-prod-001')));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
      expect(cartCubit.state.subtotalAmount, 180000);

      await tester.tap(find.byKey(const Key('cartRemoveButton-prod-001')));
      await tester.pump();

      expect(
        find.text('Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng'),
        findsOneWidget,
      );
      expect(cartCubit.state.cart.isEmpty, isTrue);
    });

    testWidgets('applies bulk discount when selected quantity reaches tier', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 50);

      await tester.pumpWidget(_wrap(cartCubit: cartCubit));

      expect(cartCubit.state.subtotalAmount, 4000000);
      expect(find.text('Khuyến mãi mua nhiều (2%):'), findsOneWidget);
      expect(find.text('-80.000\u0111'), findsOneWidget);
      expect(find.text('3.920.000\u0111'), findsOneWidget);
    });

    testWidgets('allows entering item quantity directly', (tester) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(_wrap(cartCubit: cartCubit));

      await tester.enterText(
        find.byKey(const Key('cartQuantityInput-prod-001')),
        '50',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(cartCubit.state.cart.items.single.quantity, 50);
      expect(find.text('Khuyến mãi mua nhiều (2%):'), findsOneWidget);
      expect(find.text('-80.000\u0111'), findsOneWidget);
      expect(find.text('3.920.000\u0111'), findsOneWidget);
    });

    testWidgets('toggles selected item out of totals and checkout state', (
      tester,
    ) async {
      var checkoutTapped = false;
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(
        _wrap(cartCubit: cartCubit, onCheckout: () => checkoutTapped = true),
      );

      var checkoutButton = tester.widget<FilledButton>(
        find.byKey(const Key('cartCheckoutButton')),
      );
      expect(checkoutButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('cartSelectedToggle-prod-001')));
      await tester.pump();

      expect(cartCubit.state.subtotalAmount, 0);
      checkoutButton = tester.widget<FilledButton>(
        find.byKey(const Key('cartCheckoutButton')),
      );
      expect(checkoutButton.onPressed, isNull);

      await tester.tap(find.byKey(const Key('cartSelectedToggle-prod-001')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cartCheckoutButton')));

      expect(checkoutTapped, isTrue);
    });
  });
}

Widget _wrap({
  required CartCubit cartCubit,
  VoidCallback? onCheckout,
  VoidCallback? onContinueShopping,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: BlocProvider.value(
      value: cartCubit,
      child: CartScreen(
        onCheckout: onCheckout,
        onContinueShopping: onContinueShopping,
      ),
    ),
  );
}

bool _isSystemSurfaceCard(Widget widget) {
  if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
    return false;
  }

  final decoration = widget.decoration as BoxDecoration;
  final border = decoration.border;
  return decoration.color == Colors.white &&
      decoration.borderRadius == BorderRadius.circular(18) &&
      border is Border &&
      border.top.color == const Color(0xFFE4EEF5);
}

ProductDetail _product() {
  return const ProductDetail(
    id: 'prod-001',
    name: 'Muc kho loai 1',
    slug: 'muc-kho-loai-1',
    imageUrl: 'assets/products/dried_squid.png',
    basePrice: 100000,
    unit: 'kg',
    minOrderQuantity: 2,
    stockQuantity: 600,
    status: ProductStatus.active,
    priceTiers: [
      PriceTier(
        id: 'tier-2-4',
        minQuantity: 2,
        maxQuantity: 4,
        unitPrice: 90000,
      ),
      PriceTier(id: 'tier-5-plus', minQuantity: 5, unitPrice: 80000),
    ],
  );
}
