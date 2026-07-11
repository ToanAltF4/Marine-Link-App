import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/order.dart';
import '../bloc/order_bloc.dart';

/// Bảng điều khiển cho admin/staff chọn trạng thái mới, ghi chú và lưu đơn hàng.
class AdminStatusControl extends StatefulWidget {
  final OrderDetail order;
  final String keyPrefix;

  const AdminStatusControl({
    super.key,
    required this.order,
    required this.keyPrefix,
  });

  @override
  State<AdminStatusControl> createState() => _AdminStatusControlState();
}

class _AdminStatusControlState extends State<AdminStatusControl> {
  final _noteController = TextEditingController();
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status.allowedTransitions.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant AdminStatusControl oldWidget) {
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
        AppStrings.finalOrderStatusMessage,
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
                  AppStrings.orderStatusUpdateSuccess,
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
                AppStrings.currentOrderStatus(widget.order.displayStatusLabel),
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
                  labelText: AppStrings.internalNoteLabel,
                  hintText: AppStrings.internalNoteHint,
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
                  label: Text(
                    isLoading ? AppStrings.saving : AppStrings.saveStatus,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
