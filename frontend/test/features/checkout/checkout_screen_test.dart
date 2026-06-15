import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/checkout/domain/shipping_address.dart';
import 'package:marinelink/features/checkout/domain/shipping_address_repository.dart';
import 'package:marinelink/features/checkout/domain/checkout_repository.dart';
import 'package:marinelink/features/checkout/domain/vnpay_payment.dart';
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
          shippingAddressRepository: _FakeShippingAddressRepository(),
        ),
      );

      expect(
        find.text('Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng'),
        findsOneWidget,
      );
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
          shippingAddressRepository: _FakeShippingAddressRepository(),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump();

      expect(
        find.text(
          'Ng\u01b0\u1eddi nh\u1eadn kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '\u0110\u1ecba ch\u1ec9 kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng',
        ),
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
          shippingAddressRepository: _FakeShippingAddressRepository(),
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
      expect(find.text('M\u00e3 \u0111\u01a1n ML-TEST-0001'), findsOneWidget);
      expect(cartCubit.state.cart.isEmpty, isTrue);
    });

    testWidgets('keeps cart visible while VNPAY payment is pending', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);

      await tester.pumpWidget(
        _wrap(
          cartCubit: cartCubit,
          checkoutRepository: _FakeCheckoutRepository(),
          shippingAddressRepository: _FakeShippingAddressRepository(),
        ),
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
      await tester.ensureVisible(find.text('VNPAY'));
      await tester.pump();
      await tester.tap(find.text('VNPAY'));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('checkoutSubmitButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Chờ thanh toán VNPAY'), findsOneWidget);
      expect(find.byKey(const Key('checkoutBackToCartButton')), findsOneWidget);
      expect(cartCubit.state.cart.isNotEmpty, isTrue);
      expect(cartCubit.state.cart.selectedItems, isNotEmpty);
    });

    testWidgets('loads saved shipping address for repeat checkout', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);
      final addressRepository = _FakeShippingAddressRepository(
        addresses: const [
          ShippingAddress(
            id: 'address-001',
            label: 'Kho Can Tho',
            receiverName: 'Nguyen Van A',
            receiverPhone: '0912345678',
            addressLine: '123 Tran Hung Dao, Can Tho',
            isDefault: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          cartCubit: cartCubit,
          checkoutRepository: _FakeCheckoutRepository(),
          shippingAddressRepository: addressRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('\u0110\u1ecba ch\u1ec9 \u0111\u00e3 l\u01b0u'),
        findsOneWidget,
      );
      expect(find.text('Kho Can Tho'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('checkoutShippingAddressField')),
            )
            .controller
            ?.text,
        '123 Tran Hung Dao, Can Tho',
      );
    });

    testWidgets('creates first shipping address before checkout submit', (
      tester,
    ) async {
      final cartCubit = CartCubit()..addItem(product: _product(), quantity: 2);
      final addressRepository = _FakeShippingAddressRepository();
      final checkoutRepository = _FakeCheckoutRepository();

      await tester.pumpWidget(
        _wrap(
          cartCubit: cartCubit,
          checkoutRepository: checkoutRepository,
          shippingAddressRepository: addressRepository,
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      expect(addressRepository.createCallCount, 1);
      expect(
        addressRepository.addresses.single.addressLine,
        '123 Tran Hung Dao, Can Tho',
      );
      expect(checkoutRepository.lastRequest?.shippingAddressId, 'address-001');
    });
  });
}

Widget _wrap({
  required CartCubit cartCubit,
  required CheckoutRepository checkoutRepository,
  required ShippingAddressRepository shippingAddressRepository,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: BlocProvider.value(
      value: cartCubit,
      child: CheckoutScreen(
        checkoutRepository: checkoutRepository,
        shippingAddressRepository: shippingAddressRepository,
      ),
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
  CheckoutRequest? lastRequest;

  @override
  Future<ApiResponse<CheckoutResult>> createOrder({
    required CheckoutRequest request,
    required Cart activeCart,
  }) async {
    lastRequest = request;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ApiResponse<CheckoutResult>(
      success: true,
      message: 'Order created',
      data: CheckoutResult(
        order: Order(
          id: 'order-001',
          orderCode: 'ML-TEST-0001',
          status: OrderStatus.pending,
          paymentMethod: request.paymentMethod,
          paymentStatus: request.paymentMethod == PaymentMethod.vnpay
              ? 'PENDING'
              : 'UNPAID',
          totalAmount: activeCart.subtotalAmount,
          createdAt: DateTime(2026, 6, 3),
        ),
        subtotalAmount: activeCart.subtotalAmount,
        totalItemCount: activeCart.totalSelectedItemCount,
        vnpayPayment: request.paymentMethod == PaymentMethod.vnpay
            ? const VnpayPaymentUrl(
                orderId: 'order-001',
                orderCode: 'ML-TEST-0001',
                txnRef: 'txn-001',
                paymentUrl: 'https://vnpay.test/pay',
              )
            : null,
      ),
    );
  }
}

class _FakeShippingAddressRepository implements ShippingAddressRepository {
  final List<ShippingAddress> addresses;
  int createCallCount = 0;

  _FakeShippingAddressRepository({List<ShippingAddress> addresses = const []})
    : addresses = List<ShippingAddress>.of(addresses);

  @override
  Future<ApiResponse<List<ShippingAddress>>> listAddresses() async {
    return ApiResponse<List<ShippingAddress>>(
      success: true,
      data: List<ShippingAddress>.unmodifiable(addresses),
    );
  }

  @override
  Future<ApiResponse<ShippingAddress>> createAddress(
    ShippingAddressInput input,
  ) async {
    createCallCount += 1;
    final address = ShippingAddress(
      id: 'address-${createCallCount.toString().padLeft(3, '0')}',
      label: input.label,
      receiverName: input.receiverName,
      receiverPhone: input.receiverPhone,
      addressLine: input.addressLine,
      isDefault: addresses.isEmpty || input.isDefault,
    );
    addresses.add(address);
    return ApiResponse<ShippingAddress>(success: true, data: address);
  }

  @override
  Future<ApiResponse<ShippingAddress>> updateAddress({
    required String id,
    required ShippingAddressInput input,
  }) async {
    final index = addresses.indexWhere((address) => address.id == id);
    final address = ShippingAddress(
      id: id,
      label: input.label,
      receiverName: input.receiverName,
      receiverPhone: input.receiverPhone,
      addressLine: input.addressLine,
      isDefault: input.isDefault,
    );
    addresses[index] = address;
    return ApiResponse<ShippingAddress>(success: true, data: address);
  }

  @override
  Future<ApiResponse<void>> deleteAddress(String id) async {
    addresses.removeWhere((address) => address.id == id);
    return const ApiResponse<void>(success: true);
  }
}
