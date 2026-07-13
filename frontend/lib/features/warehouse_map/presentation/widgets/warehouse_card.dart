import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/warehouse.dart';
import 'warehouse_common_widgets.dart';

/// Thẻ chi tiết một kho hàng kèm nút mở Google Maps.
///
/// Chạm vào thẻ sẽ gọi [onSelect] — màn hình dùng đúng đối tượng [warehouse]
/// này để chọn marker tương ứng trên bản đồ OSM và bay tới toạ độ của nó, nên
/// thẻ / marker / nút "Chỉ đường" luôn trỏ về cùng một điểm.
class WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback onOpenMaps;

  /// Gọi khi người dùng chạm vào thẻ (chọn kho này trên bản đồ).
  final VoidCallback? onSelect;

  /// Kho này đang được chọn trên bản đồ → làm nổi bật viền + nền.
  final bool selected;

  const WarehouseCard({
    super.key,
    required this.warehouse,
    required this.onOpenMaps,
    this.onSelect,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('warehouseCard_${warehouse.id}'),
      decoration: selected
          ? warehouseSelectedCardDecoration
          : warehouseCardDecoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('warehouseCardSelect_${warehouse.id}'),
          onTap: onSelect,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WarehouseIconTile(
                      icon: selected
                          ? Icons.location_on
                          : Icons.location_on_outlined,
                      color: selected
                          ? AppColors.primary
                          : AppColors.secondary,
                      backgroundColor: selected
                          ? AppColors.surfaceSky
                          : const Color(0xFFE8FBFA),
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
                      _InfoChip(
                        icon: Icons.call_outlined,
                        label: warehouse.phone!,
                      ),
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
                    label: const Text(AppStrings.openGoogleMaps),
                  ),
                ),
              ],
            ),
          ),
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
