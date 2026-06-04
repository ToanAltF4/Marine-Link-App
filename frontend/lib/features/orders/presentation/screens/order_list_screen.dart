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
import '../../domain/order.dart';
import '../bloc/order_bloc.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

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
      child: BuyerBackToHomeScope(
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F8FA),
          appBar: AppBar(
            title: const Text('Đơn hàng'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Lọc',
                onPressed: () {},
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          bottomNavigationBar: const BuyerBottomNav(
            currentTab: BuyerBottomNavTab.profile,
          ),
          body: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
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
                          ],
                        ),
                      ),
                    ),
                    switch (state) {
                      OrderListLoading() => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      OrderListError(:final message) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          title: 'Không tải được đơn hàng',
                          message: message,
                          actionLabel: 'Thử lại',
                          onAction: () => _reload(context),
                        ),
                      ),
                      OrderListEmpty() => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          title: 'Chưa có đơn hàng',
                          message: 'Các đơn đã đặt sẽ xuất hiện tại đây.',
                        ),
                      ),
                      OrderListLoaded(:final orders) => _OrderList(
                        orders: _filteredOrders(orders),
                      ),
                      _ => const SliverFillRemaining(hasScrollBody: false),
                    },
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _reload(BuildContext context) {
    context.read<OrderBloc>().add(OrderListRequested(status: _status));
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
    final filters = [
      (label: 'Tất cả', value: null),
      (label: 'Chờ duyệt', value: OrderStatus.pending.apiValue),
      (label: 'Đã duyệt', value: OrderStatus.confirmed.apiValue),
      (label: 'Đang giao', value: OrderStatus.shipping.apiValue),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedStatus == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
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

class _OrderList extends StatelessWidget {
  final List<Order> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          title: 'Không tìm thấy đơn hàng',
          message: 'Thử mã đơn khác hoặc đổi bộ lọc.',
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.separated(
        itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: orders.length,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

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
                onPressed: () =>
                    context.go(AppRoutes.orderDetailPath(order.id)),
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
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
