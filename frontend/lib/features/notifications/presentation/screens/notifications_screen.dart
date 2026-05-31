import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_NotificationItem> _items = [
    _NotificationItem(
      title: 'Don hang #OD2305 da duoc xac nhan',
      message: 'Kho Ca Mau da xac nhan 120kg muc kho giao vao sang mai.',
      timeLabel: '5 phut truoc',
      categoryLabel: 'Don hang',
      icon: Icons.inventory_2_outlined,
      accentColor: AppColors.primary,
      unread: true,
    ),
    _NotificationItem(
      title: 'Gia tom kho da cap nhat theo tier moi',
      message: 'Moc gia 5kg va 10kg da duoc dieu chinh cho kenh dai ly.',
      timeLabel: '25 phut truoc',
      categoryLabel: 'Gia si',
      icon: Icons.stacked_line_chart_rounded,
      accentColor: AppColors.secondary,
      unread: true,
    ),
    _NotificationItem(
      title: 'Nhan vien ho tro da phan hoi chat',
      message: 'Ban co tin nhan moi trong phong chat ve don hang dang giao.',
      timeLabel: '2 gio truoc',
      categoryLabel: 'Tin nhan',
      icon: Icons.chat_bubble_outline_rounded,
      accentColor: Color(0xFF7C3AED),
      unread: false,
    ),
    _NotificationItem(
      title: 'Lich seed catalog da dong bo',
      message: 'UI buyer da doc token moi tu Stitch kit Ocean B2B.',
      timeLabel: 'Hom qua',
      categoryLabel: 'He thong',
      icon: Icons.sync_rounded,
      accentColor: Color(0xFFEA580C),
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadItems = _items.where((item) => item.unread).toList();
    final olderItems = _items.where((item) => !item.unread).toList();

    return Scaffold(
      bottomNavigationBar: const BuyerBottomNav(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              'Thong bao',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Theo doi cap nhat don hang, chat va thay doi gia theo nhu cau mua si.',
              style: theme.textTheme.bodyMedium,
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
                      label: 'Chua doc',
                      value: '${unreadItems.length}',
                      icon: Icons.mark_chat_unread_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _NotificationSummaryCard(
                      label: 'Da dong bo',
                      value: 'Realtime',
                      icon: Icons.sync_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Moi nhat',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in unreadItems) ...[
              _NotificationTile(item: item),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 10),
            Text(
              'Truoc do',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in olderItems) ...[
              _NotificationTile(item: item),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String timeLabel;
  final String categoryLabel;
  final IconData icon;
  final Color accentColor;
  final bool unread;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.categoryLabel,
    required this.icon,
    required this.accentColor,
    required this.unread,
  });
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
  final _NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: item.unread
              ? item.accentColor.withValues(alpha: 0.24)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, color: item.accentColor),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.accentColor,
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
                      label: item.categoryLabel,
                      color: item.accentColor,
                    ),
                    _NotificationMetaChip(
                      label: item.timeLabel,
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
