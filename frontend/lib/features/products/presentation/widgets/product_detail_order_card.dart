import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_detail_card.dart';
import 'product_detail_price_formatter.dart';

class OrderQuantityCard extends StatelessWidget {
  final ProductDetail detail;
  final double effectivePrice;
  final int quantity;
  final bool outOfStock;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onAddToCart;

  const OrderQuantityCard({
    super.key,
    required this.detail,
    required this.effectivePrice,
    required this.quantity,
    required this.outOfStock,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ProductDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0110\u1eb7t h\u00e0ng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$quantity ${detail.unit}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productDetailUnitPrice(effectivePrice, detail.unit),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _QuantityButton(icon: Icons.add_rounded, onTap: onIncrease),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('addToCartButton'),
            onPressed: onAddToCart,
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: Text(
              outOfStock
                  ? 'T\u1ea1m h\u1ebft h\u00e0ng'
                  : 'Th\u00eam v\u00e0o gi\u1ecf',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
    );
  }
}
