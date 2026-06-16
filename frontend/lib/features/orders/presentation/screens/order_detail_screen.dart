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
                  OrderDetailError(:final message) => _DetailMessage(
                    title: 'Không tải được chi tiết',
                    message: message,
                    onRetry: () => context.read<OrderBloc>().add(
                      OrderDetailRequested(orderId),
                    ),
                  ),
                  OrderDetailLoaded(:final order) => _OrderDetailBody(
                    order: order,
                    adminMode: adminMode,
                    staffMode: staffMode,
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
      return 'Cập nhật trạng thái đơn';
    }
    if (adminMode) {
      return 'Giám sát trạng thái đơn';
    }
    return 'Chi tiết đơn hàng';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(order: order),
        const SizedBox(height: 12),
        if (adminMode || staffMode) ...[
          _Panel(
            key: Key(
              staffMode ? 'staffOrderStatusPanel' : 'adminOrderStatusPanel',
            ),
            title: staffMode ? 'Cập nhật trạng thái' : 'Giám sát trạng thái',
            icon: staffMode
                ? Icons.fact_check_outlined
                : Icons.admin_panel_settings_outlined,
            child: _AdminStatusControl(
              order: order,
              keyPrefix: staffMode ? 'staff' : 'admin',
            ),
          ),
          const SizedBox(height: 12),
        ],
        _Panel(
          title: 'Trạng thái',
          icon: Icons.route_outlined,
          child: _Timeline(history: order.statusHistory),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Địa chỉ giao hàng',
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
        _Panel(
          title: 'Sản phẩm đã đặt (${order.items.length})',
          icon: Icons.inventory_2_outlined,
          child: Column(
            children: order.items
                .map((item) => _OrderItemRow(item: item))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Thanh toán',
          icon: Icons.account_balance_wallet_outlined,
          child: _PaymentSummary(order: order),
        ),
        if (!adminMode &&
            !staffMode &&
            order.status == OrderStatus.completed) ...[
          const SizedBox(height: 12),
          _CompletedOrderActions(order: order),
        ],
      ],
    );
  }
}

class _CompletedOrderActions extends StatelessWidget {
  final OrderDetail order;

  const _CompletedOrderActions({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      key: const Key('buyerCompletedOrderActionsPanel'),
      title: 'Hỗ trợ sau giao hàng',
      icon: Icons.support_agent_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nếu đơn hàng có vấn đề về chất lượng, số lượng hoặc giao nhận, hãy mở kênh chat khiếu nại để staff xử lý theo mã đơn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('buyerComplaintChatButton'),
              onPressed: () =>
                  context.push(AppRoutes.chatOrderRoomPath(order.id)),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Khiếu nại đơn hàng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final OrderDetail order;

  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    return DecoratedBox(
      decoration: _panelDecoration,
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
                    'Mã đơn: ${order.orderCode}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OrderStatusBadge(
                  status: order.status.apiValue,
                  paymentMethod: order.paymentMethod.apiValue,
                  paymentStatus: order.paymentStatus,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              createdAt,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatusControl extends StatefulWidget {
  final OrderDetail order;
  final String keyPrefix;

  const _AdminStatusControl({required this.order, required this.keyPrefix});

  @override
  State<_AdminStatusControl> createState() => _AdminStatusControlState();
}

class _AdminStatusControlState extends State<_AdminStatusControl> {
  final _noteController = TextEditingController();
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status.allowedTransitions.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant _AdminStatusControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status) {
      _selectedStatus = widget.order.status.allowedTransitions.firstOrNull;
      _noteController.clear();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transitions = widget.order.status.allowedTransitions;
    if (transitions.isEmpty) {
      return Text(
        'Đơn hàng đã ở trạng thái kết thúc.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final detailBloc = context.read<OrderBloc>();
    return BlocProvider(
      create: (_) => sl<OrderBloc>(),
      child: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderStatusUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đã cập nhật trạng thái đơn hàng',
                  key: Key('adminOrderStatusSuccessSnack'),
                ),
              ),
            );
            detailBloc.add(OrderDetailRequested(widget.order.id));
          }
          if (state is OrderStatusUpdateError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is OrderStatusUpdateLoading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái hiện tại: ${widget.order.displayStatusLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: transitions.map((status) {
                  final selected = _selectedStatus == status;
                  return ChoiceChip(
                    key: Key(
                      '${widget.keyPrefix}OrderStatusOption_${status.apiValue}',
                    ),
                    selected: selected,
                    label: Text(status.displayLabel),
                    onSelected: isLoading
                        ? null
                        : (_) => setState(() => _selectedStatus = status),
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: Key('${widget.keyPrefix}OrderStatusNoteField'),
                controller: _noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú nội bộ',
                  hintText: 'VD: Đã xác nhận tồn kho và chuẩn bị giao',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: Key('${widget.keyPrefix}OrderStatusSubmitButton'),
                  onPressed: isLoading || _selectedStatus == null
                      ? null
                      : () => context.read<OrderBloc>().add(
                          OrderStatusUpdateRequested(
                            orderId: widget.order.id,
                            newStatus: _selectedStatus!.apiValue,
                            note: _noteController.text,
                          ),
                        ),
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isLoading ? 'Đang lưu' : 'Lưu trạng thái'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<OrderStatusHistory> history;

  const _Timeline({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('Chưa có lịch sử trạng thái.');
    }
    return Column(
      children: history.map((step) {
        final time = DateFormat('dd/MM HH:mm').format(step.createdAt);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OrderStatus.fromString(step.toStatus).displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (step.note != null && step.note!.isNotEmpty)
                      Text(
                        step.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _OrderItemImage(imageUrl: item.productImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productNameSnapshot,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đơn giá: ${_currency(item.unitPrice)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'x ${item.quantity} ${item.productUnitSnapshot}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currency(item.lineTotal),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemImage extends StatelessWidget {
  final String? imageUrl;

  const _OrderItemImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const Icon(Icons.set_meal_outlined, color: AppColors.primary);
    }
    return Image.network(
      url,
      key: const Key('orderItemProductImage'),
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.set_meal_outlined, color: AppColors.primary),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final OrderDetail order;

  const _PaymentSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(label: 'Tạm tính', value: _currency(order.subtotalAmount)),
        _SummaryRow(
          label: 'Phí vận chuyển',
          value: _currency(order.shippingFee),
        ),
        _SummaryRow(
          label: 'Giảm giá',
          value: '-${_currency(order.discountAmount)}',
          valueColor: AppColors.success,
        ),
        const Divider(height: 24),
        _SummaryRow(
          label: 'Tổng cộng',
          value: _currency(order.totalAmount),
          emphasized: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primary,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _DetailMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

final _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);

String _currency(double value) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(value);
}
