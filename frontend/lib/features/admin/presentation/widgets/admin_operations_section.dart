import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import 'admin_dashboard_common.dart';

/// Phần điều phối hệ thống: các lối tắt quản lý tài khoản, sản phẩm, đơn hàng.
class OperationsSection extends StatelessWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenWarehouses;

  const OperationsSection({
    super.key,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onOpenUsers,
    required this.onOpenWarehouses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminOperationsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: AppStrings.adminOperationsTitle,
          subtitle: AppStrings.adminOperationsSubtitle,
        ),
        const SizedBox(height: 12),
        ActionCard(
          key: const Key('adminUsersShortcut'),
          icon: Icons.people_alt_outlined,
          title: AppStrings.adminUsersTitle,
          description: AppStrings.adminUsersOperationDescription,
          onTap: onOpenUsers,
        ),
        const SizedBox(height: 10),
        ActionCard(
          key: const Key('adminProductsShortcut'),
          icon: Icons.inventory_2_outlined,
          title: AppStrings.adminProductsTitle,
          description: AppStrings.adminProductsOperationDescription,
          onTap: onOpenProducts,
        ),
        const SizedBox(height: 10),
        ActionCard(
          key: const Key('adminOrdersShortcut'),
          icon: Icons.visibility_outlined,
          title: AppStrings.ordersMonitoring,
          description: AppStrings.adminOrdersOperationDescription,
          onTap: onOpenOrders,
        ),
        const SizedBox(height: 10),
        ActionCard(
          key: const Key('adminWarehousesShortcut'),
          icon: Icons.location_on_outlined,
          title: AppStrings.warehouseTitle,
          description: AppStrings.warehouseShortcutDescription,
          onTap: onOpenWarehouses,
        ),
      ],
    );
  }
}

/// Thẻ lối tắt hành động với biểu tượng, tiêu đề, mô tả và mũi tên.
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: adminCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceSky,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
