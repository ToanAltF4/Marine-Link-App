import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../bloc/notification_cubit.dart';

/// Khối tổng quan số thông báo chưa đọc và tổng cộng.
class NotificationSummary extends StatelessWidget {
  final NotificationState state;

  const NotificationSummary({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('notificationsSummary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: NotificationSummaryCard(
              label: 'Chưa đọc',
              value: '${state.unreadNotifications.length}',
              icon: Icons.mark_chat_unread_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NotificationSummaryCard(
              label: 'Tổng cộng',
              value: '${state.notifications.length}',
              icon: Icons.notifications_active_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ thống kê nhỏ hiển thị một số liệu kèm nhãn và biểu tượng.
class NotificationSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const NotificationSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Bộ lọc trạng thái đọc (tất cả / chưa đọc / đã đọc).
class NotificationFilters extends StatelessWidget {
  final NotificationReadFilter selected;

  const NotificationFilters({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<NotificationReadFilter>(
        key: const Key('notificationsReadFilter'),
        segments: const [
          ButtonSegment(
            value: NotificationReadFilter.all,
            label: Text('Tất cả'),
            icon: Icon(Icons.notifications_none_rounded),
          ),
          ButtonSegment(
            value: NotificationReadFilter.unread,
            label: Text('Chưa đọc'),
            icon: Icon(Icons.mark_email_unread_outlined),
          ),
          ButtonSegment(
            value: NotificationReadFilter.read,
            label: Text('Đã đọc'),
            icon: Icon(Icons.drafts_outlined),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) {
          context.read<NotificationCubit>().changeFilter(values.first);
        },
      ),
    );
  }
}
