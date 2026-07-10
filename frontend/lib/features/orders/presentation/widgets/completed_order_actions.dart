import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/order.dart';
import 'order_detail_panel.dart';

/// Khối hỗ trợ sau giao hàng cho người mua với nút mở kênh chat khiếu nại.
class CompletedOrderActions extends StatelessWidget {
  final OrderDetail order;

  const CompletedOrderActions({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return OrderDetailPanel(
      key: const Key('buyerCompletedOrderActionsPanel'),
      title: 'Hỗ trợ sau giao hàng',
      icon: Icons.support_agent_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nếu đơn hàng có vấn đề về chất lượng, số lượng hoặc giao nhận, hãy mở kênh chat khiếu nại để staff xử lý theo mã đơn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('buyerComplaintChatButton'),
              onPressed: () =>
                  context.push(AppRoutes.chatOrderRoomPath(order.id)),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Khiếu nại đơn hàng'),
            ),
          ),
        ],
      ),
    );
  }
}
