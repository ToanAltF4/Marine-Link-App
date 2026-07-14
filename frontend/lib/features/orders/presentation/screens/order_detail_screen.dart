import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/order.dart';
import '../bloc/order_bloc.dart';
import '../widgets/admin_status_control.dart';
import '../widgets/completed_order_actions.dart';
import '../widgets/order_detail_message.dart';
import '../widgets/order_detail_panel.dart';
import '../widgets/order_item_row.dart';
import '../widgets/order_payment_summary.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final bool adminMode;
  final bool staffMode;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.adminMode = false,
    this.staffMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderBloc>()..add(OrderDetailRequested(orderId)),
      child: Builder(
        builder: (context) {
          final scaffold = Scaffold(
            key: Key(
              staffMode
                  ? 'staffOrderDetailScreen'
                  : adminMode
                  ? 'adminOrderDetailScreen'
                  : 'buyerOrderDetailScreen',
            ),
            backgroundColor: const Color(0xFFF2F8FA),
            appBar: AppBar(title: Text(_screenTitle())),
            bottomNavigationBar: adminMode || staffMode
                ? _roleBottomNav()
                : const BuyerBottomNav(currentTab: BuyerBottomNavTab.profile),
            body: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                return switch (state) {
                  OrderDetailLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  OrderDetailError(:final message) => OrderDetailMessage(
                    title: AppStrings.orderDetailLoadFailedTitle,
                    message: message,
                    onRetry: () => context.read<OrderBloc>().add(
                      OrderDetailRequested(orderId),
                    ),
                  ),
                  OrderDetailLoaded(:final order) => RefreshIndicator(
                    onRefresh: () async {
                      context.read<OrderBloc>().add(
                        OrderDetailRequested(orderId),
                      );
                      await context.read<OrderBloc>().stream.firstWhere(
                        (next) => next is! OrderDetailLoading,
                      );
                    },
                    child: _OrderDetailBody(
                      order: order,
                      adminMode: adminMode,
                      staffMode: staffMode,
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          );

          if (adminMode || staffMode) {
            return RoleBackToDashboardScope(
              dashboardLocation: _roleDashboardLocation(),
              child: scaffold,
            );
          }

          return BuyerBackToHomeScope(child: scaffold);
        },
      ),
    );
  }

  String _screenTitle() {
    if (staffMode) {
      return AppStrings.orderStatusUpdateTitle;
    }
    if (adminMode) {
      return AppStrings.orderStatusMonitorTitle;
    }
    return AppStrings.orderDetailTitle;
  }

  Widget _roleBottomNav() {
    if (staffMode) {
      return const StaffBottomNav(currentTab: StaffBottomNavTab.orders);
    }
    return const AdminBottomNav(currentTab: AdminBottomNavTab.orders);
  }

  String _roleDashboardLocation() {
    if (staffMode) {
      return AppRoutes.staffDashboard;
    }
    return AppRoutes.adminDashboard;
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderDetail order;
  final bool adminMode;
  final bool staffMode;

  const _OrderDetailBody({
    required this.order,
    required this.adminMode,
    required this.staffMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        OrderHeader(order: order),
        const SizedBox(height: 12),
        if (adminMode || staffMode) ...[
          OrderDetailPanel(
            key: Key(
              staffMode ? 'staffOrderStatusPanel' : 'adminOrderStatusPanel',
            ),
            title: staffMode
                ? AppStrings.orderStatusUpdateShort
                : AppStrings.orderStatusMonitorShort,
            icon: staffMode
                ? Icons.fact_check_outlined
                : Icons.admin_panel_settings_outlined,
            child: AdminStatusControl(
              order: order,
              keyPrefix: staffMode ? 'staff' : 'admin',
            ),
          ),
          const SizedBox(height: 12),
        ],
        OrderDetailPanel(
          title: AppStrings.productStatusLabel,
          icon: Icons.route_outlined,
          child: OrderStatusTimeline(history: order.statusHistory),
        ),
        const SizedBox(height: 12),
        OrderDetailPanel(
          title: AppStrings.shippingAddressLabel,
          icon: Icons.location_on_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.receiverName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(order.receiverPhone),
              const SizedBox(height: 4),
              Text(order.shippingAddress),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OrderDetailPanel(
          title: AppStrings.orderItemsTitle(order.items.length),
          icon: Icons.inventory_2_outlined,
          child: Column(
            children: order.items
                .map((item) => OrderItemRow(item: item))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        OrderDetailPanel(
          title: AppStrings.paymentTitle,
          icon: Icons.account_balance_wallet_outlined,
          child: OrderPaymentSummary(order: order),
        ),
        if (!adminMode &&
            !staffMode &&
            order.status == OrderStatus.completed) ...[
          const SizedBox(height: 12),
          CompletedOrderActions(order: order),
        ],
      ],
    );
  }
}
