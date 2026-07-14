import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/admin_product.dart';
import 'admin_product_styles.dart';

/// Thẻ tóm tắt kho: tổng số sản phẩm, số đang bán và số cần kiểm kho.
class AdminProductsHeader extends StatelessWidget {
  final List<AdminProduct> products;

  const AdminProductsHeader({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final activeCount = products
        .where((product) => product.status == AdminProductStatus.active)
        .length;
    final lowStockCount = products
        .where((product) => product.stockQuantity <= product.minOrderQuantity)
        .length;
    return DecoratedBox(
      key: const Key('adminProductsSummaryCard'),
      decoration: adminProductCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconTile(
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.productInventoryTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.adminProductSummary(
                      productCount: products.length,
                      activeCount: activeCount,
                      lowStockCount: lowStockCount,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô vuông bo góc chứa biểu tượng, dùng cho phần đầu trang.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
