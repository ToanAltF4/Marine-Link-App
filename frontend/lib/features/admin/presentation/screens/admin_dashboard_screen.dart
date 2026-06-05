import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/dashboard_header.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      child: Scaffold(
        key: const Key('adminDashboardScreen'),
        backgroundColor: AppColors.background,
        bottomNavigationBar: const AdminBottomNav(
          currentTab: AdminBottomNavTab.dashboard,
        ),
        body: Column(
          children: [
            DashboardHeader(
              onNotificationPressed: () =>
                  context.push(AppRoutes.adminNotifications),
              onProfilePressed: () => context.push(AppRoutes.adminProfile),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  const _SystemSummaryBand(),
                  const SizedBox(height: 20),
                  _OperationsSection(
                    onOpenOrders: () => context.push(AppRoutes.adminOrders),
                    onOpenProducts: () => context.push(AppRoutes.adminProducts),
                    onOpenUsers: () => context.push(AppRoutes.adminUsers),
                  ),
                  const SizedBox(height: 20),
                  _RecentOrdersSection(
                    onViewAll: () => context.push(AppRoutes.adminOrders),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemSummaryBand extends StatelessWidget {
  const _SystemSummaryBand();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminSystemSummaryBand'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Tổng quan vận hành',
          subtitle: 'Theo dõi sức khỏe hệ thống, doanh thu và tồn kho hôm nay.',
        ),
        const SizedBox(height: 12),
        _RevenueSummaryCard(amount: 42850000, trend: '+12%'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.pending_actions_outlined,
                label: 'Đơn chờ nhân viên xử lý',
                value: '18 đơn',
                tone: _MetricTone.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'Sắp hết hàng',
                value: '5 mã',
                tone: _MetricTone.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _NewDealersSummary(),
      ],
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  final num amount;
  final String trend;

  const _RevenueSummaryCard({required this.amount, required this.trend});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminTodayRevenueCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.payments_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doanh thu hôm nay',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MoneyFormatter.format(amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(
              label: trend,
              textColor: AppColors.success,
              backgroundColor: const Color(0xFFE8F8EF),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MetricTone { neutral, warning, danger }

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _MetricTone tone;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = _MetricTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetricTone.warning => (
        foreground: AppColors.warning,
        background: const Color(0xFFFFF7E6),
      ),
      _MetricTone.danger => (
        foreground: AppColors.error,
        background: const Color(0xFFFFEFEF),
      ),
      _MetricTone.neutral => (
        foreground: AppColors.primary,
        background: AppColors.surfaceSky,
      ),
    };

    return DecoratedBox(
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
    );
  }
}

class _NewDealersSummary extends StatelessWidget {
  const _NewDealersSummary();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.storefront_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đại lý mới trong tháng',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '12 cửa hàng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const _AvatarStack(),
          ],
        ),
      ),
    );
  }
}

class _OperationsSection extends StatelessWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenUsers;

  const _OperationsSection({
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onOpenUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminOperationsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Điều phối hệ thống',
          subtitle: 'Ưu tiên quản lý tài khoản, sản phẩm và giám sát vận hành.',
        ),
        const SizedBox(height: 12),
        _ActionCard(
          key: const Key('adminUsersShortcut'),
          icon: Icons.people_alt_outlined,
          title: 'Quản lý tài khoản',
          description: 'Duyệt đại lý, nhân viên và phân quyền truy cập.',
          onTap: onOpenUsers,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          key: const Key('adminProductsShortcut'),
          icon: Icons.inventory_2_outlined,
          title: 'Quản lý sản phẩm',
          description: 'Kiểm tra catalog, tồn kho và trạng thái bán.',
          onTap: onOpenProducts,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          key: const Key('adminOrdersShortcut'),
          icon: Icons.visibility_outlined,
          title: 'Giám sát đơn hàng',
          description:
              'Theo dõi luồng xử lý; nhân viên duyệt trạng thái chính.',
          onTap: onOpenOrders,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _IconTile(
                icon: icon,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceSky,
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _RecentOrdersSection extends StatelessWidget {
  final VoidCallback onViewAll;

  const _RecentOrdersSection({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final orders = [
      const _RecentOrder(
        code: '#ML-2901',
        buyer: 'Hải Sản Biển Đông',
        time: '10:45',
        amount: 12400000,
        label: 'Chờ duyệt',
        textColor: Color(0xFFB45309),
        backgroundColor: Color(0xFFFFF7E6),
      ),
      const _RecentOrder(
        code: '#ML-2895',
        buyer: 'Nhà hàng Sen Vàng',
        time: '09:15',
        amount: 8250000,
        label: 'Đã giao',
        textColor: AppColors.success,
        backgroundColor: Color(0xFFE8F8EF),
      ),
      const _RecentOrder(
        code: '#ML-2890',
        buyer: 'Đại lý Cô Lan',
        time: '08:30',
        amount: 5100000,
        label: 'Đang soạn',
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      ),
    ];

    return Column(
      key: const Key('adminRecentOrdersSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Đơn hàng gần đây',
                subtitle: 'Dành cho giám sát; nhân viên xử lý trực tiếp.',
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
          ],
        ),
        const SizedBox(height: 10),
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

class _RecentOrder {
  final String code;
  final String buyer;
  final String time;
  final num amount;
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _RecentOrder({
    required this.code,
    required this.buyer,
    required this.time,
    required this.amount,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });
}

class _RecentOrderTile extends StatelessWidget {
  final _RecentOrder order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _IconTile(
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
                    order.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.buyer} - ${order.time}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    MoneyFormatter.format(order.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(
              label: order.label,
              textColor: order.textColor,
              backgroundColor: order.backgroundColor,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StatusPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 36,
      child: Stack(
        alignment: Alignment.centerRight,
        children: const [
          Positioned(
            right: 40,
            child: _AvatarCircle(color: Color(0xFF0F766E), label: 'A'),
          ),
          Positioned(
            right: 20,
            child: _AvatarCircle(color: Color(0xFF38A5C7), label: 'B'),
          ),
          Positioned(
            right: 0,
            child: _AvatarCircle(
              color: AppColors.surfaceSky,
              label: '+9',
              textColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _AvatarCircle({
    required this.color,
    required this.label,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
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
