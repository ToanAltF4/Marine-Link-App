import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/dashboard_header.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/admin_dashboard.dart';
import '../cubit/admin_dashboard_cubit.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminDashboardCubit>(
      create: (_) => sl<AdminDashboardCubit>()..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

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
              child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
                builder: (context, state) {
                  switch (state.status) {
                    case AdminDashboardStatus.initial:
                    case AdminDashboardStatus.loading:
                      return const Center(
                        key: Key('adminDashboardLoading'),
                        child: CircularProgressIndicator(),
                      );
                    case AdminDashboardStatus.failure:
                      return _DashboardError(
                        message: state.errorMessage ??
                            'Không tải được dữ liệu tổng quan.',
                        onRetry: () =>
                            context.read<AdminDashboardCubit>().load(),
                      );
                    case AdminDashboardStatus.success:
                      final data = state.dashboard!;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          _SystemSummaryBand(data: data),
                          const SizedBox(height: 20),
                          _OperationsSection(
                            onOpenOrders: () =>
                                context.push(AppRoutes.adminOrders),
                            onOpenProducts: () =>
                                context.push(AppRoutes.adminProducts),
                            onOpenUsers: () =>
                                context.push(AppRoutes.adminUsers),
                          ),
                          const SizedBox(height: 20),
                          _RecentOrdersSection(
                            orders: data.recentOrders,
                            onViewAll: () =>
                                context.push(AppRoutes.adminOrders),
                          ),
                        ],
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminDashboardError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('adminDashboardRetryButton'),
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemSummaryBand extends StatelessWidget {
  final AdminDashboard data;

  const _SystemSummaryBand({required this.data});

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
        _RevenueSummaryCard(amount: data.monthlyRevenue),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                key: const Key('adminPendingOrdersCard'),
                icon: Icons.pending_actions_outlined,
                label: 'Đơn chờ nhân viên xử lý',
                value: '${data.pendingOrders} đơn',
                tone: _MetricTone.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                key: const Key('adminLowStockCard'),
                icon: Icons.inventory_2_outlined,
                label: 'Sắp hết hàng',
                value: '${data.lowStockProducts} mã',
                tone: _MetricTone.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NewDealersSummary(activeUsers: data.activeUsers),
      ],
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  final num amount;

  const _RevenueSummaryCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminMonthlyRevenueCard'),
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
                    'Doanh thu tháng này',
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
    super.key,
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
  final int activeUsers;

  const _NewDealersSummary({required this.activeUsers});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminActiveUsersCard'),
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
                    'Đại lý đang hoạt động',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeUsers đại lý',
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
  final List<AdminRecentOrder> orders;
  final VoidCallback onViewAll;

  const _RecentOrdersSection({required this.orders, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
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
        if (orders.isEmpty)
          Padding(
            key: const Key('adminRecentOrdersEmpty'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa có đơn hàng gần đây.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
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

/// Vietnamese label + pill colors for an order status code.
({String label, Color textColor, Color backgroundColor}) _orderStatusStyle(
  String status,
) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return (
        label: 'Chờ duyệt',
        textColor: const Color(0xFFB45309),
        backgroundColor: const Color(0xFFFFF7E6),
      );
    case 'CONFIRMED':
    case 'PROCESSING':
      return (
        label: 'Đang xử lý',
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
    case 'SHIPPING':
      return (
        label: 'Đang giao',
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
    case 'DELIVERED':
    case 'COMPLETED':
      return (
        label: 'Đã giao',
        textColor: AppColors.success,
        backgroundColor: const Color(0xFFE8F8EF),
      );
    case 'CANCELLED':
      return (
        label: 'Đã huỷ',
        textColor: AppColors.error,
        backgroundColor: const Color(0xFFFFEFEF),
      );
    default:
      return (
        label: status.isEmpty ? 'Không rõ' : status,
        textColor: AppColors.primary,
        backgroundColor: AppColors.surfaceSky,
      );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final AdminRecentOrder order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final style = _orderStatusStyle(order.status);
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
                    order.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    MoneyFormatter.format(order.totalAmount),
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
              label: style.label,
              textColor: style.textColor,
              backgroundColor: style.backgroundColor,
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
