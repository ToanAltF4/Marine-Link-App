import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/checkout/presentation/screens/vnpay_result_screen.dart';
import 'package:marinelink/features/products/domain/product.dart';

void main() {
  testWidgets('shows paid result and clears cart after VNPAY return', (
    tester,
  ) async {
    final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);
    final router = GoRouter(
      initialLocation:
          '${AppRoutes.vnpayResult}?success=true&orderCode=ML-20260614-0027&paymentStatus=PAID&responseCode=00',
      routes: [
        GoRoute(
          path: AppRoutes.vnpayResult,
          builder: (context, state) =>
              VnpayResultScreen(queryParameters: state.uri.queryParameters),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: cartCubit,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Thanh toán VNPAY thành công'), findsOneWidget);
    expect(find.text('ML-20260614-0027'), findsOneWidget);
    expect(cartCubit.state.cart.isEmpty, isTrue);
  });
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
