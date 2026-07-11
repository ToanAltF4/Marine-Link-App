import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/dashboard_header.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_dashboard_error.dart';
import '../widgets/admin_operations_section.dart';
import '../widgets/admin_recent_orders_section.dart';
import '../widgets/admin_summary_band.dart';

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
                      return AdminDashboardError(
                        message:
                            state.errorMessage ??
                            AppStrings.adminDashboardLoadFailed,
                        onRetry: () =>
                            context.read<AdminDashboardCubit>().load(),
                      );
                    case AdminDashboardStatus.success:
                      final data = state.dashboard!;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          SystemSummaryBand(data: data),
                          const SizedBox(height: 20),
                          OperationsSection(
                            onOpenOrders: () =>
                                context.push(AppRoutes.adminOrders),
                            onOpenProducts: () =>
                                context.push(AppRoutes.adminProducts),
                            onOpenUsers: () =>
                                context.push(AppRoutes.adminUsers),
                          ),
                          const SizedBox(height: 20),
                          RecentOrdersSection(
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
