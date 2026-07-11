import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/notification.dart';

/// Thẻ hiển thị một thông báo với biểu tượng, nội dung và các chip meta.
class NotificationTile extends StatelessWidget {
  final NotificationEntity item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.type) {
      NotificationType.order => (Icons.inventory_2_outlined, AppColors.primary),
      NotificationType.product => (
        Icons.stacked_line_chart_rounded,
        AppColors.secondary,
      ),
      NotificationType.chat => (
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF7C3AED),
      ),
      NotificationType.system => (Icons.sync_rounded, AppColors.warning),
      NotificationType.promotion => (Icons.local_offer_outlined, Colors.pink),
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !item.isRead
                  ? color.withValues(alpha: 0.32)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            key: Key('notificationUnreadDot-${item.id}'),
                            width: 9,
                            height: 9,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        NotificationMetaChip(
                          label: _formatCategory(item.type),
                          color: color,
                        ),
                        NotificationMetaChip(
                          label: _formatTime(item.createdAt),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategory(NotificationType type) => switch (type) {
    NotificationType.order => AppStrings.orderContextFallback,
    NotificationType.product => AppStrings.productsTitle,
    NotificationType.chat => AppStrings.notificationTypeChat,
    NotificationType.system => AppStrings.notificationTypeSystem,
    NotificationType.promotion => AppStrings.notificationTypePromotion,
  };

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return AppStrings.justNow;
    }
    if (diff.inMinutes < 60) {
      return AppStrings.minutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return AppStrings.hoursAgo(diff.inHours);
    }
    return AppStrings.daysAgo(diff.inDays);
  }
}

/// Chip nhỏ hiển thị nhãn meta (loại thông báo, thời gian) theo màu.
class NotificationMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const NotificationMetaChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
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
