import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

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
                    onOpenProducts: () => context.push(AppRoutes.staffProducts),
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
          title: AppStrings.staffWorkManagementTitle,
          subtitle: AppStrings.staffWorkManagementSubtitle,
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
                label: AppStrings.ordersNeedProcessing,
                value: '08',
                tone: _MetricTone.primary,
                onTap: onOpenOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.warehouse_outlined,
                label: AppStrings.warehouseNeedsCheck,
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
                      AppStrings.pendingChat,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.twelveConversations,
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
  final VoidCallback onOpenProducts;

  const _QuickActionsSection({required this.onOpenProducts});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('staffQuickActionsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: AppStrings.quickActions,
          subtitle: AppStrings.quickActionsSubtitle,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionTile(
                icon: Icons.edit_square,
                label: AppStrings.updateInventory,
                onTap: onOpenProducts,
              ),
              _QuickActionTile(
                icon: Icons.add_box_outlined,
                label: AppStrings.addProduct,
                onTap: onOpenProducts,
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
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
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
                  color: AppColors.surfaceSky,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
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
                title: AppStrings.chatSupportTitle,
                subtitle: AppStrings.dailyMessageTracking,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.staffChat),
              child: const Text(AppStrings.all),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _ChatPreviewCard(
          avatarText: 'SB',
          avatarColor: AppColors.primary,
          title: AppStrings.restaurantSongBien,
          message: AppStrings.staffInventoryConfirmMessage,
          time: '10:45',
          online: true,
        ),
        const SizedBox(height: 10),
        const _ChatPreviewCard(
          avatarText: AppStrings.dealerAvatar,
          avatarColor: AppColors.secondary,
          title: AppStrings.dealerLongHai,
          message: AppStrings.staffInboundShipmentMessage,
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
