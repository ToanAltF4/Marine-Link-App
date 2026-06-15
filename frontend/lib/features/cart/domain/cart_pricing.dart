import 'cart.dart';

class CartPricingSummary {
  final double subtotalAmount;
  final double discountRate;
  final double discountAmount;
  final double totalAmount;
  final int totalSelectedItemCount;

  const CartPricingSummary({
    required this.subtotalAmount,
    required this.discountRate,
    required this.discountAmount,
    required this.totalAmount,
    required this.totalSelectedItemCount,
  });

  factory CartPricingSummary.fromCart(Cart cart) {
    final subtotal = cart.subtotalAmount;
    final itemCount = cart.totalSelectedItemCount;
    final rate = CartBulkDiscountPolicy.rateForQuantity(itemCount);
    final discount = subtotal * rate;

    return CartPricingSummary(
      subtotalAmount: subtotal,
      discountRate: rate,
      discountAmount: discount,
      totalAmount: subtotal - discount,
      totalSelectedItemCount: itemCount,
    );
  }

  bool get hasDiscount => discountAmount > 0;

  int get discountPercent => (discountRate * 100).round();
}

class CartBulkDiscountPolicy {
  static const double fivePercent = 0.05;
  static const double tenPercent = 0.10;

  const CartBulkDiscountPolicy._();

  static double rateForQuantity(int totalQuantity) {
    if (totalQuantity >= 10) return tenPercent;
    if (totalQuantity >= 5) return fivePercent;
    return 0;
  }
}
