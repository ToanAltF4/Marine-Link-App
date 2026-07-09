import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../cart/domain/cart.dart';
import '../../../cart/domain/cart_pricing.dart';
import 'checkout_card.dart';

/// Thẻ tóm tắt đơn hàng ở đầu màn thanh toán (danh sách sản phẩm + tổng tiền).
class CheckoutSummaryCard extends StatelessWidget {
  final Cart cart;

  const CheckoutSummaryCard({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItems = cart.selectedItems;
    final pricing = CartPricingSummary.fromCart(cart);

    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tóm tắt đơn hàng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _checkoutTotalQuantityLabel(cart),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < selectedItems.length; index++) ...[
            CheckoutItemRow(item: selectedItems[index]),
            if (index != selectedItems.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
          ],
          const Divider(height: 22, color: Color(0xFFEAF0F5)),
          CheckoutMetricRow(
            label: 'Tạm tính',
            value: MoneyFormatter.format(pricing.subtotalAmount),
          ),
          const SizedBox(height: 8),
          CheckoutMetricRow(
            label: pricing.hasDiscount
                ? 'Khuyến mãi mua nhiều (${pricing.discountPercent}%)'
                : 'Khuyến mãi mua nhiều',
            value: pricing.hasDiscount
                ? '-${MoneyFormatter.format(pricing.discountAmount)}'
                : 'Chưa áp dụng',
            valueColor: pricing.hasDiscount
                ? AppColors.success
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const CheckoutMetricRow(
            label: 'Phí vận chuyển',
            value: 'Miễn phí',
            valueColor: AppColors.success,
          ),
          const Divider(height: 22, color: Color(0xFFEAF0F5)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng cộng',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    MoneyFormatter.format(pricing.totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _checkoutTotalQuantityLabel(Cart cart) {
  final selectedItems = cart.selectedItems;
  final quantity = cart.totalSelectedItemCount;
  if (selectedItems.isEmpty) {
    return '0 kg';
  }

  final unit = selectedItems.first.unit;
  final sameUnit = selectedItems.every((item) => item.unit == unit);
  return sameUnit ? '$quantity $unit' : '$quantity mục';
}

/// Một dòng sản phẩm trong thẻ tóm tắt đơn hàng.
class CheckoutItemRow extends StatelessWidget {
  final CartItem item;

  const CheckoutItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4EEF5)),
            ),
            child: const Icon(
              Icons.set_meal_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit} x '
                  '${MoneyFormatter.format(item.unitPrice)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MoneyFormatter.format(item.lineTotal),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng "nhãn — giá trị" trong phần tổng kết chi phí.
class CheckoutMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CheckoutMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
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
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
