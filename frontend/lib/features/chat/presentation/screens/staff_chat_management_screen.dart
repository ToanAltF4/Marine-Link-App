import '../../../../core/utils/date_time_formatter.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/chat.dart';
import '../cubit/staff_chat_cubit.dart';

class StaffChatManagementScreen extends StatelessWidget {
  const StaffChatManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffChatCubit>(
      create: (_) => sl<StaffChatCubit>()..load(),
      child: const _StaffChatView(),
    );
  }
}

class _StaffChatView extends StatefulWidget {
  const _StaffChatView();

  @override
  State<_StaffChatView> createState() => _StaffChatViewState();
}

class _StaffChatViewState extends State<_StaffChatView> {
  static const _refreshInterval = Duration(seconds: 4);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => context.read<StaffChatCubit>().refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffChatCubit, StaffChatState>(
      listenWhen: (previous, current) =>
          previous.actionMessage != current.actionMessage ||
          previous.actionErrorMessage != current.actionErrorMessage,
      listener: (context, state) {
        final message = state.actionErrorMessage ?? state.actionMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: state.actionErrorMessage == null
                ? AppColors.success
                : AppColors.error,
          ),
        );
      },
      child: RoleBackToDashboardScope(
        dashboardLocation: AppRoutes.staffDashboard,
        child: Scaffold(
          key: const Key('staffChatManagementScreen'),
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(AppStrings.staffChatManagementTitle),
          ),
          bottomNavigationBar: const StaffBottomNav(
            currentTab: StaffBottomNavTab.chat,
          ),
          body: BlocBuilder<StaffChatCubit, StaffChatState>(
            builder: (context, state) {
              return switch (state.status) {
                StaffChatStatus.initial ||
                StaffChatStatus.loading => const Center(
                  key: Key('staffChatLoading'),
                  child: CircularProgressIndicator(),
                ),
                StaffChatStatus.failure => _StaffChatError(
                  message: state.errorMessage ?? AppStrings.staffChatLoadFailed,
                  onRetry: () => context.read<StaffChatCubit>().load(),
                ),
                StaffChatStatus.empty ||
                StaffChatStatus.success => RefreshIndicator(
                  onRefresh: () => context.read<StaffChatCubit>().refresh(),
                  child: _StaffChatContent(state: state),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _StaffChatContent extends StatelessWidget {
  final StaffChatState state;

  const _StaffChatContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('staffChatRoomsList'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _StaffChatSummary(state: state),
        const SizedBox(height: 14),
        _StaffChatSearch(initialQuery: state.query),
        const SizedBox(height: 12),
        _StaffChatFilters(state: state),
        const SizedBox(height: 14),
        if (state.rooms.isEmpty)
          const _StaffChatEmpty()
        else
          ...state.rooms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StaffChatRoomCard(
                room: room,
                updating: state.updatingRoomId == room.roomId,
              ),
            ),
          ),
      ],
    );
  }
}

class _StaffChatSummary extends StatelessWidget {
  final StaffChatState state;

  const _StaffChatSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final openCount = state.filter == StaffChatRoomFilter.open
        ? state.rooms.length
        : state.openCount;
    final closedCount = state.filter == StaffChatRoomFilter.closed
        ? state.rooms.length
        : state.closedCount;
    return DecoratedBox(
      key: const Key('staffChatSummaryCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.support_agent_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.dealerSupportTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.staffChatSummary(openCount, closedCount),
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _StaffChatSearch extends StatefulWidget {
  final String initialQuery;

  const _StaffChatSearch({required this.initialQuery});

  @override
  State<_StaffChatSearch> createState() => _StaffChatSearchState();
}

class _StaffChatSearchState extends State<_StaffChatSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('staffChatSearchField'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: AppStrings.staffChatSearchHint,
      ),
      onSubmitted: context.read<StaffChatCubit>().setQuery,
    );
  }
}

class _StaffChatFilters extends StatelessWidget {
  final StaffChatState state;

  const _StaffChatFilters({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('staffChatFilters'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            key: const Key('staffChatFilterOpen'),
            label: AppStrings.chatOpenFilter,
            selected: state.filter == StaffChatRoomFilter.open,
            filter: StaffChatRoomFilter.open,
          ),
          _FilterChip(
            key: const Key('staffChatFilterClosed'),
            label: AppStrings.chatClosedFilter,
            selected: state.filter == StaffChatRoomFilter.closed,
            filter: StaffChatRoomFilter.closed,
          ),
          _FilterChip(
            key: const Key('staffChatFilterAll'),
            label: AppStrings.all,
            selected: state.filter == StaffChatRoomFilter.all,
            filter: StaffChatRoomFilter.all,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final StaffChatRoomFilter filter;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => context.read<StaffChatCubit>().setFilter(filter),
      ),
    );
  }
}

class _StaffChatRoomCard extends StatelessWidget {
  final StaffChatRoom room;
  final bool updating;

  const _StaffChatRoomCard({required this.room, required this.updating});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(room.isClosed);
    return DecoratedBox(
      key: Key('staffChatRoomCard_${room.roomId}'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconTile(
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceSky,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.customer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${room.customer.phone} - ${room.customer.email}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: statusStyle.label,
                  textColor: statusStyle.textColor,
                  backgroundColor: statusStyle.backgroundColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              room.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
            if (room.context case final contextData?) ...[
              if (contextData.hasOrder || contextData.hasProduct) ...[
                const SizedBox(height: 10),
                _StaffChatContextStrip(
                  key: Key('staffChatContext_${room.roomId}'),
                  roomId: room.roomId,
                  contextData: contextData,
                ),
              ],
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallBadge(
                  icon: Icons.forum_outlined,
                  label: '${room.messageCount} tin',
                ),
                _SmallBadge(
                  icon: Icons.schedule_outlined,
                  label: _formatTime(room.lastMessageAt ?? room.createdAt),
                ),
                if (room.assignedStaff != null)
                  _SmallBadge(
                    icon: Icons.badge_outlined,
                    label: room.assignedStaff!.fullName,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: Key('staffChatOpenButton_${room.roomId}'),
                    onPressed: () =>
                        context.go(AppRoutes.staffChatRoomPath(room.roomId)),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(AppStrings.openChat),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: Key('staffChatToggleButton_${room.roomId}'),
                  tooltip: room.isClosed
                      ? AppStrings.reopen
                      : AppStrings.chatClosedFilter,
                  onPressed: updating
                      ? null
                      : () => context.read<StaffChatCubit>().setRoomClosed(
                          room.roomId,
                          !room.isClosed,
                        ),
                  icon: updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          room.isClosed
                              ? Icons.lock_open_outlined
                              : Icons.done_all_outlined,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffChatContextStrip extends StatelessWidget {
  final String roomId;
  final StaffChatContext contextData;

  const _StaffChatContextStrip({
    super.key,
    required this.roomId,
    required this.contextData,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (contextData.hasOrder)
          _SmallBadge(
            key: Key('staffChatContextOrderBadge_$roomId'),
            icon: Icons.receipt_long_outlined,
            label: contextData.orderCode ?? AppStrings.orderContextFallback,
          ),
        if (contextData.orderStatus != null)
          _SmallBadge(
            key: Key('staffChatContextOrderStatusBadge_$roomId'),
            icon: Icons.local_shipping_outlined,
            label: _orderStatusLabel(contextData.orderStatus!),
          ),
        if (contextData.orderTotalAmount != null)
          _SmallBadge(
            key: Key('staffChatContextOrderTotalBadge_$roomId'),
            icon: Icons.payments_outlined,
            label: MoneyFormatter.compact(contextData.orderTotalAmount!),
          ),
        if (contextData.hasProduct)
          _SmallBadge(
            key: Key('staffChatContextProductBadge_$roomId'),
            icon: Icons.inventory_2_outlined,
            label: contextData.productName ?? AppStrings.productsTitle,
          ),
      ],
    );
  }
}

class _StaffChatError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StaffChatError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('staffChatError'),
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
              key: const Key('staffChatRetryButton'),
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffChatEmpty extends StatelessWidget {
  const _StaffChatEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('staffChatEmpty'),
      child: AppEmptyState(
        icon: Icons.mark_chat_read_outlined,
        message: AppStrings.noMatchingChatRooms,
      ),
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

class _SmallBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SmallBadge({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime? value) {
  if (value == null) return AppStrings.noMessageYet;
  return DateTimeFormatter.timeThenDate(value);
}

String _orderStatusLabel(String status) {
  return switch (status.toUpperCase()) {
    'PENDING' => AppStrings.orderStatusPending,
    'CONFIRMED' => AppStrings.orderStatusConfirmed,
    'SHIPPING' => AppStrings.orderShipping,
    'COMPLETED' => AppStrings.orderStatusCompleted,
    'CANCELLED' => AppStrings.orderCancelledAlt,
    _ => status,
  };
}

({String label, Color textColor, Color backgroundColor}) _statusStyle(
  bool isClosed,
) {
  if (isClosed) {
    return (
      label: AppStrings.chatClosedFilter,
      textColor: AppColors.success,
      backgroundColor: const Color(0xFFE8F8EF),
    );
  }
  return (
    label: AppStrings.chatOpenFilter,
    textColor: AppColors.warning,
    backgroundColor: const Color(0xFFFFF7E6),
  );
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
