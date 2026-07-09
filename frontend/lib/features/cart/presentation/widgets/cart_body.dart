import 'package:flutter/material.dart';

import '../cubit/cart_cubit.dart';
import 'cart_empty_state.dart';
import 'cart_item_card.dart';
import 'order_summary_card.dart';

/// Phần thân của màn giỏ hàng: danh sách sản phẩm hoặc trạng thái trống.
class CartBody extends StatelessWidget {
  final CartState state;
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;

  const CartBody({
    super.key,
    required this.state,
    required this.onCheckout,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    if (state.cart.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                CartEmptyState(onContinueShopping: onContinueShopping),
                const SizedBox(height: 10),
                OrderSummaryCard(state: state, onCheckout: onCheckout),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('cartScrollView'),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              for (final item in state.cart.items) ...[
                CartItemCard(item: item),
                const SizedBox(height: 8),
              ],
              OrderSummaryCard(state: state, onCheckout: onCheckout),
            ],
          ),
        ),
      ),
    );
  }
}
