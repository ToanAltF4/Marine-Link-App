import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/order.dart';

/// Dòng thời gian hiển thị lịch sử chuyển trạng thái của đơn hàng.
class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusHistory> history;

  const OrderStatusTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('Chưa có lịch sử trạng thái.');
    }
    return Column(
      children: history.map((step) {
        final time = DateFormat('dd/MM HH:mm').format(step.createdAt);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OrderStatus.fromString(step.toStatus).displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (step.note != null && step.note!.isNotEmpty)
                      Text(
                        step.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
