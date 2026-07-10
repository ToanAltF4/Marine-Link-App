import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/warehouse.dart';
import 'warehouse_common_widgets.dart';

/// Thẻ tổng quan hiển thị số kho đang hoạt động ở đầu danh sách.
class WarehouseSummary extends StatelessWidget {
  final List<Warehouse> warehouses;

  const WarehouseSummary({super.key, required this.warehouses});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('warehouseSummaryCard'),
      decoration: warehouseCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const WarehouseIconTile(
              icon: Icons.warehouse_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${warehouses.length} kho đang hoạt động',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn kho gần nhất để xem vị trí và mở chỉ đường trên Google Maps.',
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
