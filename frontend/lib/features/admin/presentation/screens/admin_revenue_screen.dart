import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_revenue.dart';
import '../cubit/admin_revenue_cubit.dart';
import '../widgets/admin_dashboard_common.dart';
import '../widgets/admin_revenue_daily_list.dart';
import '../widgets/admin_revenue_month_selector.dart';
import '../widgets/admin_revenue_top_products.dart';

/// ADMIN revenue analytics screen.
/// Default view = current month; a month selector (up to 24 months back) and an
/// optional day-range filter reload the report through the same endpoint.
class AdminRevenueScreen extends StatelessWidget {
  const AdminRevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminRevenueCubit>(
      create: (_) => sl<AdminRevenueCubit>()..load(),
      child: const _AdminRevenueView(),
    );
  }
}

class _AdminRevenueView extends StatelessWidget {
  const _AdminRevenueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminRevenueScreen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.adminRevenueTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AdminRevenueCubit, AdminRevenueState>(
        builder: (context, state) {
          final cubit = context.read<AdminRevenueCubit>();
          return Column(
            children: [
              AdminRevenueMonthSelector(
                selectedMonth: state.selectedMonth ?? cubit.currentMonth,
                earliestMonth: cubit.earliestMonth,
                currentMonth: cubit.currentMonth,
                today: cubit.today,
                customRange: state.customRange,
                rangeFrom: state.rangeFrom,
                rangeTo: state.rangeTo,
                onSelectMonth: cubit.selectMonth,
                onSelectRange: cubit.selectRange,
                onClearRange: () => cubit.selectMonth(
                  state.selectedMonth ?? cubit.currentMonth,
                ),
              ),
              Expanded(child: _RevenueBody(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueBody extends StatelessWidget {
  final AdminRevenueState state;

  const _RevenueBody({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AdminRevenueStatus.initial:
      case AdminRevenueStatus.loading:
        return const Center(
          key: Key('adminRevenueLoading'),
          child: CircularProgressIndicator(),
        );
      case AdminRevenueStatus.failure:
        return _RevenueError(
          message: state.errorMessage ?? AppStrings.adminRevenueLoadFailed,
          onRetry: () {
            final cubit = context.read<AdminRevenueCubit>();
            final from = state.rangeFrom;
            final to = state.rangeTo;
            if (state.customRange && from != null && to != null) {
              cubit.selectRange(from, to);
            } else {
              cubit.selectMonth(state.selectedMonth ?? cubit.currentMonth);
            }
          },
        );
      case AdminRevenueStatus.success:
        final report = state.report!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _TotalRevenueCard(report: report),
            const SizedBox(height: 20),
            const SectionHeader(
              title: AppStrings.adminRevenueDailyTitle,
              subtitle: AppStrings.adminRevenueDailySubtitle,
            ),
            const SizedBox(height: 12),
            AdminRevenueDailyList(series: report.dailySeries),
            const SizedBox(height: 24),
            const SectionHeader(
              title: AppStrings.adminRevenueTopProductsTitle,
              subtitle: AppStrings.adminRevenueSelectMonth,
            ),
            const SizedBox(height: 12),
            AdminRevenueTopProducts(products: report.topProducts),
          ],
        );
    }
  }
}

/// Prominent total-revenue figure for the selected period.
class _TotalRevenueCard extends StatelessWidget {
  final RevenueReport report;

  const _TotalRevenueCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminRevenueTotal'),
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.adminRevenueTotalLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              MoneyFormatter.format(report.totalRevenue),
              key: const Key('adminRevenueTotalAmount'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!report.hasSales) ...[
              const SizedBox(height: 6),
              Text(
                AppStrings.adminRevenueEmpty,
                key: const Key('adminRevenueEmpty'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevenueError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RevenueError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminRevenueError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('adminRevenueRetryButton'),
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
