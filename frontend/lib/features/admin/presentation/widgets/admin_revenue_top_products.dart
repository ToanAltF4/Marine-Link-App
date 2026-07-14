import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_revenue.dart';
import 'admin_dashboard_common.dart';

/// Numbered ranking of best-selling products: name + quantity on the left,
/// revenue right-aligned.
class AdminRevenueTopProducts extends StatelessWidget {
  final List<TopProduct> products;

  const AdminRevenueTopProducts({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return DecoratedBox(
        key: const Key('adminRevenueTopEmpty'),
        decoration: adminCardDecoration,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(AppStrings.adminRevenueTopEmpty),
        ),
      );
    }

    return DecoratedBox(
      key: const Key('adminRevenueTopProducts'),
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < products.length; i++)
              _TopProductRow(rank: i + 1, product: products[i]),
          ],
        ),
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final TopProduct product;

  const _TopProductRow({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSky,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.adminRevenueSoldQuantity(product.quantitySold),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MoneyFormatter.format(product.revenue),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
