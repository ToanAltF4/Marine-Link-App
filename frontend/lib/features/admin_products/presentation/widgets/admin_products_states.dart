import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import 'admin_product_styles.dart';

/// Trạng thái lỗi khi không tải được danh sách sản phẩm, kèm nút thử lại.
class AdminProductsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminProductsError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminProductsError'),
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
            FilledButton(
              key: const Key('adminProductsRetryButton'),
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng khi chưa có sản phẩm nào trong kho.
class AdminProductsEmpty extends StatelessWidget {
  const AdminProductsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('adminProductsEmpty'),
      child: AppEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'Chưa có sản phẩm. Sản phẩm mới sẽ hiển thị sau khi được tạo.',
      ),
    );
  }
}

/// Thông báo hiển thị khi bộ lọc hiện tại không khớp sản phẩm nào.
class FilteredEmptyState extends StatelessWidget {
  const FilteredEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminProductsFilteredEmpty'),
      decoration: adminProductCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Không có sản phẩm phù hợp với bộ lọc.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
