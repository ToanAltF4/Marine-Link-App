import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_dashboard.dart';
import 'admin_dashboard_common.dart';

/// Nhãn tiếng Việt và màu pill cho một mã trạng thái đơn hàng.
({String label, Color textColor, Color backgroundColor}) _orderStatusStyle(
  String status,
) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return (
        label: 'Chờ duyệt',
        textColor: const Color(0xFFB45309),
        backgroundColor: const Color(0xFFFFF7E6),
      );
    case 'CONFIRMED':
    case 'PROCESSING':
      return (
        label: 'Đang xử lý',
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
    case 'SHIPPING':
      return (
        label: 'Đang giao',
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
    case 'DELIVERED':
    case 'COMPLETED':
      return (
        label: 'Đã giao',
        textColor: AppColors.success,
        backgroundColor: const Color(0xFFE8F8EF),
      );
    case 'CANCELLED':
      return (
        label: 'Đã huỷ',
        textColor: AppColors.error,
        backgroundColor: const Color(0xFFFFEFEF),
      );
    default:
      return (
        label: status.isEmpty ? 'Không rõ' : status,
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
  }
}

/// Phần đơn hàng gần đây phục vụ giám sát, kèm nút xem tất cả.
class RecentOrdersSection extends StatelessWidget {
  final List<AdminRecentOrder> orders;
  final VoidCallback onViewAll;

  const RecentOrdersSection({
    super.key,
    required this.orders,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminRecentOrdersSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'Đơn hàng gần đây',
                subtitle: 'Dành cho giám sát; nhân viên xử lý trực tiếp.',
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
          ],
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          Padding(
            key: const Key('adminRecentOrdersEmpty'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa có đơn hàng gần đây.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentOrderTile(order: order),
            ),
          ),
      ],
    );
  }
}

/// Ô hiển thị một đơn hàng gần đây: mã đơn, tổng tiền và trạng thái.
class _RecentOrderTile extends StatelessWidget {
  final AdminRecentOrder order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final style = _orderStatusStyle(order.status);
    return DecoratedBox(
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(
              icon: Icons.shopping_bag_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    MoneyFormatter.format(order.totalAmount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: style.label,
              textColor: style.textColor,
              backgroundColor: style.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}
