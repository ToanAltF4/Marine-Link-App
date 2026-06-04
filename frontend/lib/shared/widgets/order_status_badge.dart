import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, String) _statusInfo(String status) => switch (status) {
    'PENDING' => (AppColors.orderPending, 'Chờ duyệt'),
    'CONFIRMED' => (AppColors.orderConfirmed, 'Đã xác nhận'),
    'SHIPPING' => (AppColors.orderShipping, 'Đang giao'),
    'COMPLETED' => (AppColors.orderCompleted, 'Hoàn tất'),
    'CANCELLED' => (AppColors.orderCancelled, 'Đã hủy'),
    _ => (Colors.grey, status),
  };
}
