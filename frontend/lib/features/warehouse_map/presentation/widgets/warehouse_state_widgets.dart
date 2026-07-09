import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_empty_state.dart';

/// Trạng thái lỗi khi không tải được danh sách kho, kèm nút thử lại.
class WarehouseError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const WarehouseError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('warehouseMapError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('warehouseMapRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng khi chưa có kho hàng nào đang hoạt động.
class WarehouseEmpty extends StatelessWidget {
  const WarehouseEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('warehouseMapEmpty'),
      child: AppEmptyState(
        icon: Icons.warehouse_outlined,
        message: 'Chưa có kho hàng đang hoạt động.',
      ),
    );
  }
}
