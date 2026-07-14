import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/cart.dart';
import '../../domain/cart_pricing.dart';
import '../cubit/cart_cubit.dart';
import 'cart_card.dart';

const _cartInnerRadius = 14.0;

/// Thẻ tổng kết đơn hàng kèm nút tiến hành đặt hàng.
class OrderSummaryCard extends StatelessWidget {
  final CartState state;
  final VoidCallback onCheckout;

  const OrderSummaryCard({
    super.key,
    required this.state,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricing = CartPricingSummary.fromCart(state.cart);

    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.orderTotalTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAF0F5)),
          const SizedBox(height: 13),
          SummaryRow(
            label: AppStrings.totalQuantityLabel,
            value: _totalQuantityLabel(state.cart),
            valueColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: AppStrings.subtotalLabelWithColon,
            value: _formatVnd(pricing.subtotalAmount),
            valueColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: pricing.hasDiscount
                ? AppStrings.bulkDiscount(pricing.discountPercent)
                : AppStrings.bulkDiscountLabel,
            value: pricing.hasDiscount
                ? '-${_formatVnd(pricing.discountAmount)}'
                : AppStrings.discountNotApplied,
            valueColor: pricing.hasDiscount
                ? AppColors.success
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const SummaryRow(
            label: AppStrings.shippingFeeLabelWithColon,
            value: AppStrings.freeShipping,
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEAF0F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.totalLabelWithColon,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatVnd(pricing.totalAmount),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('cartCheckoutButton'),
            onPressed: state.canCheckout ? onCheckout : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFB7C8D7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cartInnerRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text(AppStrings.proceedToCheckout),
          ),
        ],
      ),
    );
  }
}

/// Một dòng nhãn - giá trị trong thẻ tổng kết đơn hàng.
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475569),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _formatVnd(num amount) {
  final normalized = amount.round();
  return '${NumberFormat.decimalPattern('vi_VN').format(normalized)}${AppStrings.currencySymbol}';
}

String _totalQuantityLabel(Cart cart) {
  final selectedItems = cart.selectedItems;
  final quantity = cart.totalSelectedItemCount;
  if (selectedItems.isEmpty) {
    return '0 kg';
  }

  final unit = selectedItems.first.unit;
  final sameUnit = selectedItems.every((item) => item.unit == unit);
  return sameUnit
      ? AppStrings.quantityWithUnit(quantity, unit)
      : AppStrings.quantityItemCount(quantity);
}
