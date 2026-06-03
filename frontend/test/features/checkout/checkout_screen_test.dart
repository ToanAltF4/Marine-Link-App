import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/checkout/domain/checkout_repository.dart';
import 'package:marinelink/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:marinelink/features/orders/domain/order.dart';
import 'package:marinelink/features/products/domain/product.dart';

void main() {
  group('CheckoutScreen', () {
    testWidgets('shows empty cart state when no selected items exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          cartCubit: CartCubit(),
          checkoutRepository: _FakeCheckoutRepository(),
        ),
      );

      expect(find.text('Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng'), findsOneWidget);
      expect(find.byKey(const Key('checkoutSubmitButton')), findsNothing);
    });

    testWidgets('validates receiver form before submitting checkout', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(
        _wrap(
          cartCubit: cartCubit,
          checkoutRepository: _FakeCheckoutRepository(),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump();

      expect(
        find.text('Ng\u01b0\u1eddi nh\u1eadn kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng'),
        findsOneWidget,
      );
      expect(
        find.text('S\u1ed1 \u0111i\u1ec7n tho\u1ea1i kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng'),
        findsOneWidget,
      );
      expect(
        find.text('\u0110\u1ecba ch\u1ec9 kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng'),
        findsOneWidget,
      );
    });

    testWidgets('submits checkout, shows success, and clears cart cache', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(
        _wrap(
          cartCubit: cartCubit,
          checkoutRepository: _FakeCheckoutRepository(),
        ),
      );

      expect(find.textContaining('Muc kho loai 1'), findsOneWidget);
      expect(find.textContaining('180'), findsWidgets);

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
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      expect(find.byKey(const Key('checkoutSuccessPanel')), findsOneWidget);
      expect(find.textContaining('ML-TEST-0001'), findsOneWidget);
      expect(cartCubit.state.cart.isEmpty, isTrue);
    });
  });
}

Widget _wrap({
  required CartCubit cartCubit,
  required CheckoutRepository checkoutRepository,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: BlocProvider.value(
      value: cartCubit,
      child: CheckoutScreen(checkoutRepository: checkoutRepository),
    ),
  );
}

ProductDetail _product() {
  return const ProductDetail(
    id: 'prod-001',
    name: 'Muc kho loai 1',
    slug: 'muc-kho-loai-1',
    imageUrl: 'https://example.com/muc-kho.png',
    basePrice: 100000,
    unit: 'kg',
    minOrderQuantity: 2,
    stockQuantity: 10,
    status: ProductStatus.active,
    priceTiers: [
      PriceTier(
        id: 'tier-2-4',
        minQuantity: 2,
        maxQuantity: 4,
        unitPrice: 90000,
      ),
    ],
  );
}

class _FakeCheckoutRepository implements CheckoutRepository {
  @override
  Future<ApiResponse<CheckoutResult>> createOrder({
    required CheckoutRequest request,
    required Cart activeCart,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ApiResponse<CheckoutResult>(
      success: true,
      message: 'Order created',
      data: CheckoutResult(
        order: Order(
          id: 'order-001',
          orderCode: 'ML-TEST-0001',
          status: OrderStatus.pending,
          totalAmount: activeCart.subtotalAmount,
          createdAt: DateTime(2026, 6, 3),
        ),
        subtotalAmount: activeCart.subtotalAmount,
        totalItemCount: activeCart.totalSelectedItemCount,
      ),
    );
  }
}
