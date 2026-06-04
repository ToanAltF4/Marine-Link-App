import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/app.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/router/app_router.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/checkout/data/shipping_address_mock_repository.dart';
import 'package:marinelink/features/checkout/domain/shipping_address_repository.dart';
import 'package:marinelink/features/products/data/product_mock_repository.dart';
import 'package:marinelink/features/products/domain/product.dart';
import 'package:marinelink/features/products/domain/product_repository.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/shared/navigation/buyer_navigation.dart';

void main() {
  setUp(BuyerNavigation.resetForTesting);
  tearDown(BuyerNavigation.resetForTesting);

  testWidgets('keeps buyer tabs cached after checkout view orders flow', (
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
    final productRepository = _CountingProductRepository();
    await sl.unregister<ProductRepository>();
    sl.registerLazySingleton<ProductRepository>(() => productRepository);
    await sl.unregister<ShippingAddressRepository>();
    sl.registerLazySingleton<ShippingAddressRepository>(
      () => ShippingAddressMockRepository(),
    );
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
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('homeQuickSearchField')),
      'home kept',
    );

    await tester.tap(find.text('S\u1ea3n ph\u1ea9m'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('productSearchField')),
      'tom kho',
    );

    await tester.tap(find.text('Trang ch\u1ee7'));
    await tester.pumpAndSettle();
    var homeField = tester.widget<TextField>(
      find.byKey(const Key('homeQuickSearchField')),
    );
    expect(homeField.controller?.text, 'home kept');

    await tester.tap(find.text('S\u1ea3n ph\u1ea9m'));
    await tester.pumpAndSettle();
    var productField = tester.widget<TextField>(
      find.byKey(const Key('productSearchField')),
    );
    expect(productField.controller?.text, 'tom kho');

    final context = tester.element(find.byKey(const Key('productSearchField')));
    context.read<CartCubit>().addItem(product: _checkoutProduct(), quantity: 2);
    expect(context.read<CartCubit>().state.canCheckout, isTrue);
    GoRouter.of(context).go(AppRoutes.checkout);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('checkoutReceiverNameField')), findsOneWidget);

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

    final viewOrdersButton = tester.widget<FilledButton>(
      find.byKey(const Key('checkoutViewOrdersButton')),
    );
    viewOrdersButton.onPressed!();
    await tester.pump(const Duration(milliseconds: 700));
    final requestCountAfterOrders = productRepository.getProductsCallCount;

    await tester.tap(find.text('Trang ch\u1ee7'));
    await tester.pump(const Duration(milliseconds: 500));
    homeField = tester.widget<TextField>(
      find.byKey(const Key('homeQuickSearchField')),
    );
    expect(homeField.controller?.text, 'home kept');
    expect(productRepository.getProductsCallCount, requestCountAfterOrders);

    await tester.tap(find.text('S\u1ea3n ph\u1ea9m'));
    await tester.pump(const Duration(milliseconds: 500));
    productField = tester.widget<TextField>(
      find.byKey(const Key('productSearchField')),
    );
    expect(productField.controller?.text, 'tom kho');
    expect(productRepository.getProductsCallCount, requestCountAfterOrders);
  });
}

ProductDetail _checkoutProduct() {
  return const ProductDetail(
    id: 'prod-001',
    name: 'Muc kho loai 1',
    slug: 'muc-kho-loai-1',
    imageUrl: 'assets/products/dried_squid.png',
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

class _CountingProductRepository extends ProductMockRepository {
  int getProductsCallCount = 0;

  @override
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 0,
    int size = 20,
    String? query,
    String? categoryId,
    bool? featured,
    String? status,
    String? sort,
  }) {
    getProductsCallCount += 1;
    return super.getProducts(
      page: page,
      size: size,
      query: query,
      categoryId: categoryId,
      featured: featured,
      status: status,
      sort: sort,
    );
  }
}
