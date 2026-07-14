import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/cart/domain/cart_pricing.dart';

void main() {
  group('CartBulkDiscountPolicy', () {
    test('applies no discount below fifty kilograms', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(49), 0);
    });

    test('applies two percent from 50 to 99 kilograms', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(50), 0.02);
      expect(CartBulkDiscountPolicy.rateForQuantity(99), 0.02);
    });

    test('applies four percent from 100 to 199 kilograms', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(100), 0.04);
      expect(CartBulkDiscountPolicy.rateForQuantity(199), 0.04);
    });

    test('applies six percent from 200 to 499 kilograms', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(200), 0.06);
      expect(CartBulkDiscountPolicy.rateForQuantity(499), 0.06);
    });

    test('applies eight percent from 500 kilograms', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(500), 0.08);
    });
  });

  group('CartPricingSummary', () {
    test('does not apply bulk discount across different products', () {
      const cart = Cart(
        items: [
          CartItem(
            productId: 'shrimp',
            productName: 'Tom kho',
            productImageUrl: '',
            unit: 'kg',
            quantity: 30,
            unitPrice: 100,
            stockQuantity: 100,
          ),
          CartItem(
            productId: 'squid',
            productName: 'Muc kho',
            productImageUrl: '',
            unit: 'kg',
            quantity: 20,
            unitPrice: 100,
            stockQuantity: 100,
          ),
        ],
      );

      final summary = CartPricingSummary.fromCart(cart);

      expect(summary.subtotalAmount, 5000);
      expect(summary.discountAmount, 0);
      expect(summary.totalAmount, 5000);
    });

    test('applies bulk discount only to eligible product lines', () {
      const cart = Cart(
        items: [
          CartItem(
            productId: 'shrimp',
            productName: 'Tom kho',
            productImageUrl: '',
            unit: 'kg',
            quantity: 50,
            unitPrice: 100,
            stockQuantity: 100,
          ),
          CartItem(
            productId: 'squid',
            productName: 'Muc kho',
            productImageUrl: '',
            unit: 'kg',
            quantity: 20,
            unitPrice: 100,
            stockQuantity: 100,
          ),
        ],
      );

      final summary = CartPricingSummary.fromCart(cart);

      expect(summary.subtotalAmount, 7000);
      expect(summary.discountPercent, 2);
      expect(summary.discountAmount, 100);
      expect(summary.totalAmount, 6900);
    });
  });
}
