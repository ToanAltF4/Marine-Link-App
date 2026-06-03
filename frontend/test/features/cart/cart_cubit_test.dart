import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:marinelink/features/products/domain/product.dart';

void main() {
  group('Cart', () {
    test('starts empty with zero totals', () {
      const cart = Cart();

      expect(cart.isEmpty, isTrue);
      expect(cart.items, isEmpty);
      expect(cart.subtotalAmount, 0);
      expect(cart.totalSelectedItemCount, 0);
    });

    test('returns new carts when adding and removing items', () {
      const cart = Cart();
      final item = _cartItem(productId: 'prod-001', quantity: 2);

      final withItem = cart.upsertItem(item);
      final emptied = withItem.removeItem('prod-001');

      expect(cart.items, isEmpty);
      expect(withItem.items.single, item);
      expect(emptied.isEmpty, isTrue);
    });

    test('totals include only selected items', () {
      final selected = _cartItem(productId: 'prod-001', quantity: 2);
      final unselected = _cartItem(
        productId: 'prod-002',
        quantity: 5,
        unitPrice: 30000,
        selected: false,
      );

      final cart = Cart(items: [selected, unselected]);

      expect(cart.subtotalAmount, 200000);
      expect(cart.totalSelectedItemCount, 2);
    });
  });

  group('CartCubit', () {
    blocTest<CartCubit, CartState>(
      'starts with an empty cart',
      build: CartCubit.new,
      verify: (cubit) {
        expect(cubit.state.cart.isEmpty, isTrue);
        expect(cubit.state.subtotalAmount, 0);
        expect(cubit.state.totalSelectedItemCount, 0);
        expect(cubit.state.canCheckout, isFalse);
      },
    );

    blocTest<CartCubit, CartState>(
      'adds an item using min quantity and matching price tier',
      build: CartCubit.new,
      act: (cubit) => cubit.addItem(product: _product(), quantity: 1),
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.items.single.quantity, 'quantity', 2)
            .having(
              (state) => state.cart.items.single.unitPrice,
              'unitPrice',
              90000,
            )
            .having(
              (state) => state.cart.items.single.selectedPriceTierId,
              'selectedPriceTierId',
              'tier-2-4',
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 180000)
            .having((state) => state.totalSelectedItemCount, 'itemCount', 2)
            .having((state) => state.canCheckout, 'canCheckout', true),
      ],
    );

    blocTest<CartCubit, CartState>(
      'increments an existing item and recalculates totals',
      build: CartCubit.new,
      act: (cubit) {
        final product = _product();
        cubit.addItem(product: product, quantity: 2);
        cubit.addItem(product: product, quantity: 3);
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.items.length, 'item length', 1)
            .having((state) => state.cart.items.single.quantity, 'quantity', 5)
            .having(
              (state) => state.cart.items.single.unitPrice,
              'unitPrice',
              80000,
            )
            .having(
              (state) => state.cart.items.single.selectedPriceTierId,
              'selectedPriceTierId',
              'tier-5-plus',
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 400000),
      ],
    );

    blocTest<CartCubit, CartState>(
      'updates quantity and recalculates price tier for the edited item',
      build: CartCubit.new,
      act: (cubit) {
        cubit.addItem(product: _product(), quantity: 2);
        cubit.updateQuantity('prod-001', 5);
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.items.single.quantity, 'quantity', 5)
            .having(
              (state) => state.cart.items.single.unitPrice,
              'unitPrice',
              80000,
            )
            .having(
              (state) => state.cart.items.single.selectedPriceTierId,
              'selectedPriceTierId',
              'tier-5-plus',
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 400000),
      ],
    );

    blocTest<CartCubit, CartState>(
      'returns to base price when updated quantity no longer matches a tier',
      build: CartCubit.new,
      act: (cubit) {
        cubit.addItem(product: _productWithHighVolumeTierOnly(), quantity: 5);
        cubit.updateQuantity('prod-tiered', 1);
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.items.single.quantity, 'quantity', 1)
            .having(
              (state) => state.cart.items.single.unitPrice,
              'unitPrice',
              100000,
            )
            .having(
              (state) => state.cart.items.single.selectedPriceTierId,
              'selectedPriceTierId',
              isNull,
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 100000),
      ],
    );

    blocTest<CartCubit, CartState>(
      'removes the last item and exposes an empty non-checkout state',
      build: CartCubit.new,
      act: (cubit) {
        cubit.addItem(product: _product(), quantity: 2);
        cubit.removeItem('prod-001');
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.isEmpty, 'isEmpty', true)
            .having((state) => state.subtotalAmount, 'subtotalAmount', 0)
            .having((state) => state.totalSelectedItemCount, 'itemCount', 0)
            .having((state) => state.canCheckout, 'canCheckout', false),
      ],
    );

    blocTest<CartCubit, CartState>(
      'toggles item selection out of checkout totals and back in',
      build: CartCubit.new,
      act: (cubit) {
        cubit.addItem(product: _product(), quantity: 2);
        cubit.toggleSelected('prod-001');
        cubit.toggleSelected('prod-001');
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having(
              (state) => state.cart.items.single.selected,
              'selected',
              false,
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 0)
            .having((state) => state.canCheckout, 'canCheckout', false),
        isA<CartState>()
            .having(
              (state) => state.cart.items.single.selected,
              'selected',
              true,
            )
            .having((state) => state.subtotalAmount, 'subtotalAmount', 180000)
            .having((state) => state.canCheckout, 'canCheckout', true),
      ],
    );

    blocTest<CartCubit, CartState>(
      'clears all items',
      build: CartCubit.new,
      act: (cubit) {
        cubit.addItem(product: _product(), quantity: 2);
        cubit.clearCart();
      },
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((state) => state.cart.isEmpty, 'isEmpty', true)
            .having((state) => state.canCheckout, 'canCheckout', false),
      ],
    );

    blocTest<CartCubit, CartState>(
      'does not emit when editing an unknown product id',
      build: CartCubit.new,
      act: (cubit) {
        cubit.updateQuantity('unknown', 3);
        cubit.toggleSelected('unknown');
      },
      expect: () => <CartState>[],
    );
  });
}

CartItem _cartItem({
  required String productId,
  int quantity = 1,
  double unitPrice = 100000,
  bool selected = true,
}) {
  return CartItem(
    productId: productId,
    productName: 'Muc kho',
    productImageUrl: '',
    unit: 'kg',
    quantity: quantity,
    unitPrice: unitPrice,
    selected: selected,
    minOrderQuantity: 1,
    stockQuantity: 10,
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
      PriceTier(id: 'tier-5-plus', minQuantity: 5, unitPrice: 80000),
    ],
  );
}

ProductDetail _productWithHighVolumeTierOnly() {
  return const ProductDetail(
    id: 'prod-tiered',
    name: 'Tom kho loai 1',
    slug: 'tom-kho-loai-1',
    imageUrl: 'https://example.com/tom-kho.png',
    basePrice: 100000,
    unit: 'kg',
    minOrderQuantity: 1,
    stockQuantity: 10,
    status: ProductStatus.active,
    priceTiers: [
      PriceTier(id: 'tier-5-plus', minQuantity: 5, unitPrice: 80000),
    ],
  );
}
