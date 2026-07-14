import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import 'cart_card.dart';

const _cartInnerRadius = 14.0;

/// Trạng thái giỏ hàng trống kèm nút tiếp tục chọn sản phẩm.
class CartEmptyState extends StatelessWidget {
  final VoidCallback onContinueShopping;

  const CartEmptyState({super.key, required this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CartCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.cartEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onContinueShopping,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text(AppStrings.chooseProduct),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_cartInnerRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
