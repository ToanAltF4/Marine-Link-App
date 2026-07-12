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
    final selectedItems = cart.selectedItems;
    final subtotal = selectedItems.fold(
      0.0,
      (sum, item) => sum + item.lineTotal,
    );
    var discount = 0.0;
    var highestRate = 0.0;
    for (final item in selectedItems) {
      final rate = CartBulkDiscountPolicy.rateForQuantity(item.quantity);
      discount += item.lineTotal * rate;
      if (rate > highestRate) {
        highestRate = rate;
      }
    }

    return CartPricingSummary(
      subtotalAmount: subtotal,
      discountRate: highestRate,
      discountAmount: discount,
      totalAmount: subtotal - discount,
      totalSelectedItemCount: cart.totalSelectedItemCount,
    );
  }

  bool get hasDiscount => discountAmount > 0;

  int get discountPercent => (discountRate * 100).round();
}

class CartBulkDiscountPolicy {
  static const int twoPercentMinQuantity = 50;
  static const int fourPercentMinQuantity = 100;
  static const int sixPercentMinQuantity = 200;
  static const int eightPercentMinQuantity = 500;
  static const double twoPercent = 0.02;
  static const double fourPercent = 0.04;
  static const double sixPercent = 0.06;
  static const double eightPercent = 0.08;

  const CartBulkDiscountPolicy._();

  static double rateForQuantity(int totalQuantity) {
    if (totalQuantity >= eightPercentMinQuantity) return eightPercent;
    if (totalQuantity >= sixPercentMinQuantity) return sixPercent;
    if (totalQuantity >= fourPercentMinQuantity) return fourPercent;
    if (totalQuantity >= twoPercentMinQuantity) return twoPercent;
    return 0;
  }
}
