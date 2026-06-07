import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
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

class _StaffChatView extends StatelessWidget {
  const _StaffChatView();

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
      child: AppBackExitScope(
        child: Scaffold(
          key: const Key('staffChatManagementScreen'),
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Qu\u1ea3n l\u00fd chat')),
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
                  message:
                      state.errorMessage ??
                      'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c danh s\u00e1ch chat.',
                  onRetry: () => context.read<StaffChatCubit>().load(),
                ),
                StaffChatStatus.empty ||
                StaffChatStatus.success => _StaffChatContent(state: state),
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
                    'H\u1ed7 tr\u1ee3 \u0111\u1ea1i l\u00fd',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$openCount ch\u01b0a x\u1eed l\u00fd - $closedCount \u0111\u00e3 x\u1eed l\u00fd',
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
        hintText:
            'T\u00ecm theo t\u00ean, email, s\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
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
            label: 'Ch\u01b0a x\u1eed l\u00fd',
            selected: state.filter == StaffChatRoomFilter.open,
            filter: StaffChatRoomFilter.open,
          ),
          _FilterChip(
            key: const Key('staffChatFilterClosed'),
            label: '\u0110\u00e3 x\u1eed l\u00fd',
            selected: state.filter == StaffChatRoomFilter.closed,
            filter: StaffChatRoomFilter.closed,
          ),
          _FilterChip(
            key: const Key('staffChatFilterAll'),
            label: 'T\u1ea5t c\u1ea3',
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
                    label: const Text('M\u1edf chat'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: Key('staffChatComplaintButton_${room.roomId}'),
                  tooltip: 'T\u1ea1o khi\u1ebfu n\u1ea1i',
                  onPressed: updating
                      ? null
                      : () => _showComplaintSheet(context, room),
                  icon: const Icon(Icons.report_problem_outlined),
                ),
                IconButton(
                  key: Key('staffChatToggleButton_${room.roomId}'),
                  tooltip: room.isClosed
                      ? 'M\u1edf l\u1ea1i'
                      : '\u0110\u00e3 x\u1eed l\u00fd',
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
              child: const Text('Th\u1eed l\u1ea1i'),
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
        message:
            'Kh\u00f4ng c\u00f3 ph\u00f2ng chat ph\u00f9 h\u1ee3p v\u1edbi b\u1ed9 l\u1ecdc.',
      ),
    );
  }
}

class _ComplaintSheet extends StatefulWidget {
  final StaffChatRoom room;

  const _ComplaintSheet({required this.room});

  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<_ComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text =
        'Khi\u1ebfu n\u1ea1i t\u1eeb ${widget.room.customer.fullName}';
    _descriptionController.text = widget.room.summary;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const Key('staffChatComplaintSheet'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'T\u1ea1o khi\u1ebfu n\u1ea1i',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('staffChatComplaintTitleField'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Ti\u00eau \u0111\u1ec1',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('staffChatComplaintDescriptionField'),
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'M\u00f4 t\u1ea3',
                  ),
                  minLines: 3,
                  maxLines: 5,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('staffChatComplaintSaveButton'),
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('L\u01b0u khi\u1ebfu n\u1ea1i'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<StaffChatCubit>().createComplaint(
      roomId: widget.room.roomId,
      title: _titleController.text,
      description: _descriptionController.text,
      messageId: widget.room.lastMessage?.id,
    );
    if (!mounted) return;
    if (context.read<StaffChatCubit>().state.actionErrorMessage == null) {
      Navigator.of(context).pop();
    }
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

  const _SmallBadge({required this.label, required this.icon});

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

void _showComplaintSheet(BuildContext context, StaffChatRoom room) {
  final cubit = context.read<StaffChatCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ComplaintSheet(room: room),
    ),
  );
}

String _formatTime(DateTime? value) {
  if (value == null) return 'Ch\u01b0a c\u00f3 tin';
  return DateFormat('HH:mm dd/MM').format(value.toLocal());
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng';
  }
  return null;
}

({String label, Color textColor, Color backgroundColor}) _statusStyle(
  bool isClosed,
) {
  if (isClosed) {
    return (
      label: '\u0110\u00e3 x\u1eed l\u00fd',
      textColor: AppColors.success,
      backgroundColor: const Color(0xFFE8F8EF),
    );
  }
  return (
    label: 'Ch\u01b0a x\u1eed l\u00fd',
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
