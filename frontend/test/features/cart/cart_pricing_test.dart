import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/cart/domain/cart_pricing.dart';

void main() {
  group('CartBulkDiscountPolicy', () {
    test('applies no discount below five selected units', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(4), 0);
    });

    test('applies five percent from five selected units', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(5), 0.05);
      expect(CartBulkDiscountPolicy.rateForQuantity(9), 0.05);
    });

    test('applies ten percent from ten selected units', () {
      expect(CartBulkDiscountPolicy.rateForQuantity(10), 0.10);
    });
  });
}
