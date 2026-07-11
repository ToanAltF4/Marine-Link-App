import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_dashboard.dart';
import 'admin_dashboard_common.dart';

/// Sắc thái màu cho thẻ chỉ số nhanh trên bảng điều khiển.
enum MetricTone { neutral, warning, danger }

/// Dải tổng quan vận hành: doanh thu, đơn chờ xử lý, tồn kho và đại lý.
class SystemSummaryBand extends StatelessWidget {
  final AdminDashboard data;

  /// Tapping the revenue card opens the dedicated revenue screen.
  final VoidCallback? onViewRevenue;

  const SystemSummaryBand({super.key, required this.data, this.onViewRevenue});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminSystemSummaryBand'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: AppStrings.operationsOverviewTitle,
          subtitle: AppStrings.operationsOverviewSubtitle,
        ),
        const SizedBox(height: 12),
        RevenueSummaryCard(
          amount: data.monthlyRevenue,
          onViewRevenue: onViewRevenue,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                key: const Key('adminPendingOrdersCard'),
                icon: Icons.pending_actions_outlined,
                label: AppStrings.pendingOrdersMetricLabel,
                value: AppStrings.orderCount(data.pendingOrders),
                tone: MetricTone.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                key: const Key('adminLowStockCard'),
                icon: Icons.inventory_2_outlined,
                label: AppStrings.lowStockFull,
                value: AppStrings.codeCount(data.lowStockProducts),
                tone: MetricTone.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NewDealersSummary(activeUsers: data.activeUsers),
      ],
    );
  }
}

/// Thẻ hiển thị doanh thu tháng hiện tại. Chạm để mở trang doanh thu chi tiết.
class RevenueSummaryCard extends StatelessWidget {
  final num amount;
  final VoidCallback? onViewRevenue;

  const RevenueSummaryCard({
    super.key,
    required this.amount,
    this.onViewRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminMonthlyRevenueCard'),
      decoration: adminCardDecoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('adminViewRevenueButton'),
          onTap: onViewRevenue,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconTile(
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
                        AppStrings.monthlyRevenue,
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            AppStrings.viewRevenue,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.primary,
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
      ),
    );
  }
}

/// Thẻ chỉ số nhanh (đơn chờ xử lý, tồn kho...) với sắc thái cảnh báo.
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MetricTone tone;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = MetricTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MetricTone.warning => (
        foreground: AppColors.warning,
        background: const Color(0xFFFFF7E6),
      ),
      MetricTone.danger => (
        foreground: AppColors.error,
        background: const Color(0xFFFFEFEF),
      ),
      MetricTone.neutral => (
        foreground: AppColors.primary,
        background: AppColors.surfaceSky,
      ),
    };

    return DecoratedBox(
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
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

/// Thẻ tổng số đại lý đang hoạt động kèm cụm ảnh đại diện.
class NewDealersSummary extends StatelessWidget {
  final int activeUsers;

  const NewDealersSummary({super.key, required this.activeUsers});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminActiveUsersCard'),
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconTile(
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
                    AppStrings.activeDealers,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.activeDealerCount(activeUsers),
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

/// Cụm ảnh đại diện xếp chồng minh hoạ cho danh sách đại lý.
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

/// Một vòng tròn ảnh đại diện đơn lẻ trong cụm [_AvatarStack].
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
