import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/notification.dart';
import '../bloc/notification_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationCubit>()..loadNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state.status == NotificationStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final unreadItems = state.notifications.where((item) => !item.isRead).toList();
            final olderItems = state.notifications.where((item) => item.isRead).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text(
                      'Thông báo',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    'Theo dõi cập nhật đơn hàng, chat và thay đổi giá theo nhu cầu mua sỉ.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NotificationSummaryCard(
                          label: 'Chưa đọc',
                          value: '${unreadItems.length}',
                          icon: Icons.mark_chat_unread_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _NotificationSummaryCard(
                          label: 'Đã đồng bộ',
                          value: 'Realtime',
                          icon: Icons.sync_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (unreadItems.isNotEmpty) ...[
                  Text(
                    'Mới nhất',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in unreadItems) ...[
                    GestureDetector(
                      onTap: () => _handleNotificationClick(context, item),
                      child: _NotificationTile(item: item),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 10),
                ],
                if (olderItems.isNotEmpty) ...[
                  Text(
                    'Trước đó',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in olderItems) ...[
                    GestureDetector(
                      onTap: () => _handleNotificationClick(context, item),
                      child: _NotificationTile(item: item),
                    ),
                    const SizedBox(height: 12), // Chỉ cần 1 dòng này thôi
                  ],
                ],
                if (state.notifications.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text('Không có thông báo nào', style: theme.textTheme.bodyMedium),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
  // Chèn vào khoảng dòng 128
  void _handleNotificationClick(BuildContext context, NotificationEntity item) {
    // 1. Đánh dấu đã đọc nếu là thông báo mới
    if (!item.isRead) {
      context.read<NotificationCubit>().markAsRead(item.id);
    }

    // 2. Điều hướng dựa trên loại thông báo sử dụng GoRouter
    if (item.relatedId != null) {
      if (item.type == NotificationType.order) {
        // Dùng context.push để GoRouter quản lý lịch sử và URL
        context.push(AppRoutes.orderDetailPath(item.relatedId!));
      } else if (item.type == NotificationType.product) {
        context.push(AppRoutes.productDetailPath(item.relatedId!));
      }
    }
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NotificationSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // Map NotificationType to Icon and Color
    final (icon, color) = switch (item.type) {
      NotificationType.order => (Icons.inventory_2_outlined, AppColors.primary),
      NotificationType.product => (Icons.stacked_line_chart_rounded, AppColors.secondary),
      NotificationType.chat => (Icons.chat_bubble_outline_rounded, const Color(0xFF7C3AED)),
      NotificationType.system => (Icons.sync_rounded, const Color(0xFFEA580C)),
      NotificationType.promotion => (Icons.local_offer_outlined, Colors.pink),
    };

    // Simple time formatter
    final timeLabel = _formatTime(item.createdAt);
    final categoryLabel = _formatCategory(item.type);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: !item.isRead ? color.withValues(alpha: 0.24) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NotificationMetaChip(
                      label: categoryLabel,
                      color: color,
                    ),
                    _NotificationMetaChip(
                      label: timeLabel,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(NotificationType type) => switch (type) {
        NotificationType.order => 'Đơn hàng',
        NotificationType.product => 'Giá sỉ',
        NotificationType.chat => 'Tin nhắn',
        NotificationType.system => 'Hệ thống',
        NotificationType.promotion => 'Khuyến mãi',
      };

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return 'Hôm qua';
  }
}

class _NotificationMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _NotificationMetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
