import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/warehouse.dart';
import 'warehouse_common_widgets.dart';

/// Thẻ chi tiết một kho hàng kèm nút mở Google Maps.
class WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback onOpenMaps;

  const WarehouseCard({
    super.key,
    required this.warehouse,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('warehouseCard_${warehouse.id}'),
      decoration: warehouseCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WarehouseIconTile(
                  icon: Icons.location_on_outlined,
                  color: AppColors.secondary,
                  backgroundColor: Color(0xFFE8FBFA),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        warehouse.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (warehouse.openingHours != null)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: warehouse.openingHours!,
                  ),
                if (warehouse.phone != null)
                  _InfoChip(icon: Icons.call_outlined, label: warehouse.phone!),
                _InfoChip(
                  icon: Icons.explore_outlined,
                  label:
                      '${warehouse.latitude.toStringAsFixed(4)}, ${warehouse.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: Key('warehouseOpenMapsButton_${warehouse.id}'),
                onPressed: onOpenMaps,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Mở Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
