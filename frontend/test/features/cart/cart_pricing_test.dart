import 'package:flutter_test/flutter_test.dart';
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
}
