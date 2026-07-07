import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/dashboard_header.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      child: Scaffold(
        key: const Key('staffDashboardScreen'),
        backgroundColor: AppColors.background,
        bottomNavigationBar: const StaffBottomNav(
          currentTab: StaffBottomNavTab.work,
        ),
        body: Column(
          children: [
            DashboardHeader(
              hasNotification: true,
              onNotificationPressed: () =>
                  context.push(AppRoutes.staffNotifications),
              onProfilePressed: () => context.push(AppRoutes.staffProfile),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _WorkOverviewSection(
                    onOpenChats: () => context.push(AppRoutes.staffChat),
                    onOpenOrders: () => context.push(AppRoutes.staffOrders),
                    onOpenWarehouses: () =>
                        context.push(AppRoutes.staffWarehouses),
                  ),
                  const SizedBox(height: 20),
                  _QuickActionsSection(
                    onOpenOrders: () => context.push(AppRoutes.staffOrders),
                  ),
                  const SizedBox(height: 20),
                  const _SupportChatSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkOverviewSection extends StatelessWidget {
  final VoidCallback onOpenChats;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenWarehouses;

  const _WorkOverviewSection({
    required this.onOpenChats,
    required this.onOpenOrders,
    required this.onOpenWarehouses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('staffWorkOverviewSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Quản lý công việc',
          subtitle: 'Ưu tiên chat đang chờ, đơn cần xử lý và kho cần kiểm.',
        ),
        const SizedBox(height: 12),
        _WaitingChatCard(onTap: onOpenChats),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                key: const Key('staffOrdersShortcut'),
                icon: Icons.fact_check_outlined,
                label: 'Đơn cần xử lý',
                value: '08',
                tone: _MetricTone.primary,
                onTap: onOpenOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.warehouse_outlined,
                label: 'Kho cần kiểm',
                value: '03',
                tone: _MetricTone.teal,
                onTap: onOpenWarehouses,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaitingChatCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WaitingChatCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('staffWaitingChatCard'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconTile(
                icon: Icons.chat_bubble_outline,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceSky,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat đang chờ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12 cuộc hội thoại',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MetricTone { primary, teal, danger }

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _MetricTone tone;
  final VoidCallback onTap;

  const _MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetricTone.primary => (
        foreground: AppColors.primary,
        background: AppColors.surfaceSky,
      ),
      _MetricTone.teal => (
        foreground: const Color(0xFF0F766E),
        background: const Color(0xFFE6FFFB),
      ),
      _MetricTone.danger => (
        foreground: AppColors.error,
        background: const Color(0xFFFFEFEF),
      ),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: icon,
                color: colors.foreground,
                backgroundColor: colors.background,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onOpenOrders;

  const _QuickActionsSection({required this.onOpenOrders});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('staffQuickActionsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Thao tác nhanh',
          subtitle: 'Các công việc nhân viên xử lý thường xuyên trong ca.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionTile(
                icon: Icons.qr_code_scanner_outlined,
                label: 'Quét mã kho',
                onTap: () {},
              ),
              _QuickActionTile(
                icon: Icons.edit_square,
                label: 'Cập nhật tồn',
                onTap: () {},
              ),
              _QuickActionTile(
                icon: Icons.warning_amber_outlined,
                label: 'Báo cáo sự cố',
                background: const Color(0xFFFFEFEF),
                iconColor: AppColors.error,
                onTap: () {},
              ),
              _QuickActionTile(
                icon: Icons.local_shipping_outlined,
                label: 'Xử lý đơn',
                onTap: onOpenOrders,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    this.background = AppColors.surfaceSky,
    this.iconColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportChatSection extends StatelessWidget {
  const _SupportChatSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('staffSupportChatSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Chat hỗ trợ',
                subtitle: 'Theo dõi tin nhắn cần phản hồi trong ngày.',
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.staffChat),
              child: const Text('Tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _ChatPreviewCard(
          avatarText: 'SB',
          avatarColor: AppColors.primary,
          title: 'Nhà hàng Sóng Biển',
          message: 'Sản phẩm tôm hùm xanh đợt này cần xác nhận tồn.',
          time: '10:45',
          online: true,
        ),
        const SizedBox(height: 10),
        const _ChatPreviewCard(
          avatarText: 'ĐL',
          avatarColor: AppColors.secondary,
          title: 'Đại lý Long Hải',
          message: 'Đã nhận được 200kg cá thu, chờ lịch giao tiếp.',
          time: '09:12',
          online: false,
        ),
      ],
    );
  }
}

class _ChatPreviewCard extends StatelessWidget {
  final String avatarText;
  final Color avatarColor;
  final String title;
  final String message;
  final String time;
  final bool online;

  const _ChatPreviewCard({
    required this.avatarText,
    required this.avatarColor,
    required this.title,
    required this.message,
    required this.time,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.textSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const SizedBox(width: 12, height: 12),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              time,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
