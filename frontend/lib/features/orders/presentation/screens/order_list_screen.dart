import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/order_status_badge.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/order.dart';
import '../bloc/order_bloc.dart';

class OrderListScreen extends StatefulWidget {
  final bool adminMode;
  final bool staffMode;

  const OrderListScreen({
    super.key,
    this.adminMode = false,
    this.staffMode = false,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _searchController = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderBloc>()..add(const OrderListRequested()),
      child: Builder(
        builder: (context) {
          final scaffold = Scaffold(
            key: Key(
              widget.staffMode
                  ? 'staffOrderListScreen'
                  : widget.adminMode
                  ? 'adminOrderListScreen'
                  : 'buyerOrderListScreen',
            ),
            backgroundColor: const Color(0xFFF2F8FA),
            appBar: AppBar(title: Text(_screenTitle()), centerTitle: true),
            bottomNavigationBar: widget.adminMode || widget.staffMode
                ? _roleBottomNav()
                : const BuyerBottomNav(currentTab: BuyerBottomNavTab.profile),
            body: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                final stateKeyPrefix = _stateKeyPrefix();
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload(context);
                    await context.read<OrderBloc>().stream.firstWhere(
                      (next) => next is! OrderListLoading,
                    );
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SearchField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 14),
                              _StatusFilters(
                                selectedStatus: _status,
                                onSelected: (status) {
                                  setState(() => _status = status);
                                  _reload(context);
                                },
                              ),
                              if (state is OrderListLoaded) ...[
                                const SizedBox(height: 12),
                                _ResultCount(
                                  count: _filteredOrders(state.orders).length,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      switch (state) {
                        OrderListLoading() => SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            key: Key('${stateKeyPrefix}Loading'),
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                        OrderListError(:final message) => SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            key: Key('${stateKeyPrefix}Error'),
                            title: 'Không tải được đơn hàng',
                            message: message,
                            actionLabel: 'Thử lại',
                            onAction: () => _reload(context),
                          ),
                        ),
                        OrderListEmpty() => SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            key: Key('${stateKeyPrefix}Empty'),
                            title: 'Chưa có đơn hàng',
                            message: 'Các đơn đã đặt sẽ xuất hiện tại đây.',
                          ),
                        ),
                        OrderListLoaded(:final orders) => _OrderList(
                          orders: _filteredOrders(orders),
                          adminMode: widget.adminMode,
                          staffMode: widget.staffMode,
                          stateKeyPrefix: stateKeyPrefix,
                        ),
                        _ => const SliverFillRemaining(hasScrollBody: false),
                      },
                    ],
                  ),
                );
              },
            ),
          );

          if (widget.adminMode || widget.staffMode) {
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

  void _reload(BuildContext context) {
    context.read<OrderBloc>().add(OrderListRequested(status: _status));
  }

  String _stateKeyPrefix() {
    if (widget.staffMode) return 'staffOrders';
    if (widget.adminMode) return 'adminOrders';
    return 'buyerOrders';
  }

  Widget _roleBottomNav() {
    if (widget.staffMode) {
      return const StaffBottomNav(currentTab: StaffBottomNavTab.orders);
    }
    return const AdminBottomNav(currentTab: AdminBottomNavTab.orders);
  }

  String _roleDashboardLocation() {
    if (widget.staffMode) {
      return AppRoutes.staffDashboard;
    }
    return AppRoutes.adminDashboard;
  }

  String _screenTitle() {
    if (widget.staffMode) {
      return 'Đơn cần xử lý';
    }
    if (widget.adminMode) {
      return 'Giám sát đơn hàng';
    }
    return 'Đơn hàng';
  }

  List<Order> _filteredOrders(List<Order> orders) {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return orders;
    }
    return orders
        .where((order) => order.orderCode.toLowerCase().contains(keyword))
        .toList();
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Tìm mã đơn hàng (VD: ML-2025)...',
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onSelected;

  const _StatusFilters({
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <({String label, String? value})>[
      (label: 'Tất cả', value: null),
      for (final status in OrderStatus.values)
        (label: status.displayLabel, value: status.apiValue),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedStatus == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: Key('orderFilterChip_${filter.value ?? 'ALL'}'),
              selected: selected,
              label: Text(filter.label),
              onSelected: (_) => onSelected(filter.value),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResultCount extends StatelessWidget {
  final int count;

  const _ResultCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$count đơn',
        key: const Key('orderListResultCount'),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final bool adminMode;
  final bool staffMode;
  final String stateKeyPrefix;

  const _OrderList({
    required this.orders,
    required this.adminMode,
    required this.staffMode,
    required this.stateKeyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          key: Key('${stateKeyPrefix}FilteredEmpty'),
          title: 'Không tìm thấy đơn hàng',
          message: 'Thử mã đơn khác hoặc đổi bộ lọc.',
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.separated(
        itemBuilder: (context, index) => _OrderCard(
          order: orders[index],
          adminMode: adminMode,
          staffMode: staffMode,
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: orders.length,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool adminMode;
  final bool staffMode;

  const _OrderCard({
    required this.order,
    required this.adminMode,
    required this.staffMode,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy - hh:mm a').format(order.createdAt);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110B3760),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '#${order.orderCode}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status.apiValue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 6),
                Text(date),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Trạng thái',
                    value: order.status.displayLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(
                    label: 'Tổng tiền',
                    value: _currency(order.totalAmount),
                    alignRight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                key: Key(
                  staffMode
                      ? 'staffOrderDetailButton_${order.id}'
                      : adminMode
                      ? 'adminOrderDetailButton_${order.id}'
                      : 'buyerOrderDetailButton_${order.id}',
                ),
                onPressed: () => _openDetail(context),
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final detailPath = _detailPath(order.id);
    if (adminMode || staffMode) {
      context.push(detailPath);
      return;
    }
    context.go(detailPath);
  }

  String _detailPath(String orderId) {
    if (staffMode) {
      return AppRoutes.staffOrderDetailPath(orderId);
    }
    if (adminMode) {
      return AppRoutes.adminOrderDetailPath(orderId);
    }
    return AppRoutes.orderDetailPath(orderId);
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _Metric({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EEF5)),
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _currency(double value) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(value);
}
