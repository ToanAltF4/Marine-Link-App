import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/broadcast_cubit.dart';
import '../bloc/notification_cubit.dart';
import '../widgets/broadcast_history.dart';
import '../widgets/notification_header.dart';
import '../widgets/notification_sections.dart';
import '../widgets/notification_summary.dart';

class NotificationsScreen extends StatelessWidget {
  /// Admin/staff see the broadcast composer + history; dealers do not.
  final bool canManageBroadcasts;

  const NotificationsScreen({super.key, this.canManageBroadcasts = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<NotificationCubit>()..loadNotifications(),
        ),
        if (canManageBroadcasts)
          BlocProvider(create: (_) => sl<BroadcastCubit>()..loadBroadcasts()),
      ],
      child: _NotificationsView(canManageBroadcasts: canManageBroadcasts),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final bool canManageBroadcasts;

  const _NotificationsView({required this.canManageBroadcasts});

  @override
  Widget build(BuildContext context) {
    final user = _currentUser(context);

    return Scaffold(
      key: const Key('notificationsScreen'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: NotificationBottomNav(user: user),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                final notificationCubit = context.read<NotificationCubit>();
                final broadcastCubit = canManageBroadcasts
                    ? context.read<BroadcastCubit>()
                    : null;
                await notificationCubit.loadNotifications();
                await broadcastCubit?.loadBroadcasts();
              },
              child: ListView(
                key: const Key('notificationsScrollView'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  NotificationHeader(user: user),
                  const SizedBox(height: 18),
                  if (canManageBroadcasts) ...[
                    const _BroadcastManager(),
                    const SizedBox(height: 20),
                  ],
                  NotificationSummary(state: state),
                  const SizedBox(height: 16),
                  NotificationFilters(selected: state.filter),
                  const SizedBox(height: 18),
                  if (state.status == NotificationStatus.loading)
                    const SizedBox(
                      height: 360,
                      child: AppLoadingIndicator(
                        key: Key('notificationsLoading'),
                        message: AppStrings.loadingNotifications,
                      ),
                    )
                  else if (state.status == NotificationStatus.failure)
                    SizedBox(
                      height: 360,
                      child: AppErrorState(
                        key: const Key('notificationsError'),
                        message:
                            state.errorMessage ??
                            AppStrings.notificationsLoadFailed,
                        onRetry: () => context
                            .read<NotificationCubit>()
                            .loadNotifications(),
                      ),
                    )
                  else if (state.status == NotificationStatus.empty)
                    const SizedBox(
                      height: 360,
                      child: AppEmptyState(
                        key: Key('notificationsEmpty'),
                        message: AppStrings.notificationsEmpty,
                        icon: Icons.notifications_none_rounded,
                      ),
                    )
                  else
                    NotificationSections(state: state, user: user),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  User? _currentUser(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user : null;
  }
}

/// Admin/staff broadcast composer + sent-history with delete.
class _BroadcastManager extends StatefulWidget {
  const _BroadcastManager();

  @override
  State<_BroadcastManager> createState() => _BroadcastManagerState();
}

class _BroadcastManagerState extends State<_BroadcastManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final created = await context.read<BroadcastCubit>().createBroadcast(
      title: _titleController.text,
      body: _bodyController.text,
    );
    if (created && mounted) {
      _titleController.clear();
      _bodyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<BroadcastCubit, BroadcastState>(
      listenWhen: (prev, curr) =>
          prev.infoMessage != curr.infoMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.infoMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.infoMessage!)));
        } else if (state.errorMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        return Container(
          key: const Key('broadcastComposer'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.broadcastCreateTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.broadcastCreateSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('broadcastTitleField'),
                      controller: _titleController,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notificationTitleLabel,
                        counterText: '',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? AppStrings.notificationTitleRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('broadcastBodyField'),
                      controller: _bodyController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notificationBodyLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? AppStrings.notificationBodyRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('broadcastSubmitButton'),
                        onPressed: state.submitting ? null : _submit,
                        icon: state.submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          state.submitting
                              ? AppStrings.sending
                              : AppStrings.sendNotification,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.broadcastHistoryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              BroadcastHistory(state: state),
            ],
          ),
        );
      },
    );
  }
}
