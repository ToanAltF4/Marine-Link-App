import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/notification.dart';
import '../bloc/notification_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationCubit>()..loadNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final user = _currentUser(context);

    return Scaffold(
      key: const Key('notificationsScreen'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _NotificationBottomNav(user: user),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return ListView(
              key: const Key('notificationsScrollView'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _NotificationHeader(user: user),
                const SizedBox(height: 18),
                _NotificationSummary(state: state),
                const SizedBox(height: 16),
                _NotificationFilters(selected: state.filter),
                const SizedBox(height: 18),
                if (state.status == NotificationStatus.loading)
                  const SizedBox(
                    height: 360,
                    child: AppLoadingIndicator(
                      key: Key('notificationsLoading'),
                      message: 'Đang tải thông báo',
                    ),
                  )
                else if (state.status == NotificationStatus.failure)
                  SizedBox(
                    height: 360,
                    child: AppErrorState(
                      key: const Key('notificationsError'),
                      message:
                          state.errorMessage ??
                          'Không tải được danh sách thông báo.',
                      onRetry: () =>
                          context.read<NotificationCubit>().loadNotifications(),
                    ),
                  )
                else if (state.status == NotificationStatus.empty)
                  const SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      key: Key('notificationsEmpty'),
                      message: 'Chưa có thông báo phù hợp.',
                      icon: Icons.notifications_none_rounded,
                    ),
                  )
                else
                  _NotificationSections(state: state, user: user),
              ],
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

class _NotificationBottomNav extends StatelessWidget {
  final User? user;

  const _NotificationBottomNav({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user?.isStaff == true) {
      return const StaffBottomNav(currentTab: StaffBottomNavTab.work);
    }
    if (user?.isAdmin == true) {
      return const AdminBottomNav(currentTab: AdminBottomNavTab.dashboard);
    }
    return const BuyerBottomNav(currentTab: BuyerBottomNavTab.home);
  }
}

class _NotificationHeader extends StatelessWidget {
  final User? user;

  const _NotificationHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const Key('notificationsBackButton'),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(_fallbackLocation(user));
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông báo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Theo dõi cập nhật đơn hàng, sản phẩm và phản hồi hỗ trợ.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fallbackLocation(User? user) {
    if (user?.isAdmin == true) {
      return AppRoutes.adminDashboard;
    }
    if (user?.isStaff == true) {
      return AppRoutes.staffDashboard;
    }
    return AppRoutes.home;
  }
}

class _NotificationSummary extends StatelessWidget {
  final NotificationState state;

  const _NotificationSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('notificationsSummary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NotificationSummaryCard(
              label: 'Chưa đọc',
              value: '${state.unreadNotifications.length}',
              icon: Icons.mark_chat_unread_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NotificationSummaryCard(
              label: 'Tổng cộng',
              value: '${state.notifications.length}',
              icon: Icons.notifications_active_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NotificationSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  final NotificationReadFilter selected;

  const _NotificationFilters({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<NotificationReadFilter>(
        key: const Key('notificationsReadFilter'),
        segments: const [
          ButtonSegment(
            value: NotificationReadFilter.all,
            label: Text('Tất cả'),
            icon: Icon(Icons.notifications_none_rounded),
          ),
          ButtonSegment(
            value: NotificationReadFilter.unread,
            label: Text('Chưa đọc'),
            icon: Icon(Icons.mark_email_unread_outlined),
          ),
          ButtonSegment(
            value: NotificationReadFilter.read,
            label: Text('Đã đọc'),
            icon: Icon(Icons.drafts_outlined),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) {
          context.read<NotificationCubit>().changeFilter(values.first);
        },
      ),
    );
  }
}

class _NotificationSections extends StatelessWidget {
  final NotificationState state;
  final User? user;

  const _NotificationSections({required this.state, required this.user});

  @override
  Widget build(BuildContext context) {
    final unreadItems = state.unreadNotifications;
    final readItems = state.readNotifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unreadItems.isNotEmpty) ...[
          const _SectionTitle(title: 'Mới nhất'),
          const SizedBox(height: 12),
          for (final item in unreadItems) ...[
            _NotificationTile(
              key: Key('notificationTile-${item.id}'),
              item: item,
              onTap: () => _handleNotificationTap(context, item, user),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (readItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionTitle(title: 'Trước đó'),
          const SizedBox(height: 12),
          for (final item in readItems) ...[
            _NotificationTile(
              key: Key('notificationTile-${item.id}'),
              item: item,
              onTap: () => _handleNotificationTap(context, item, user),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationEntity item,
    User? user,
  ) {
    if (!item.isRead) {
      context.read<NotificationCubit>().markAsRead(item.id);
    }

    final location = _targetLocation(item, user);
    if (location != null) {
      context.push(location);
    }
  }

  String? _targetLocation(NotificationEntity item, User? user) {
    if (item.type == NotificationType.order && item.relatedOrderId != null) {
      if (user?.isAdmin == true) {
        return AppRoutes.adminOrderDetailPath(item.relatedOrderId!);
      }
      if (user?.isStaff == true) {
        return AppRoutes.staffOrderDetailPath(item.relatedOrderId!);
      }
      return AppRoutes.orderDetailPath(item.relatedOrderId!);
    }

    if (item.type == NotificationType.product &&
        item.relatedProductId != null) {
      return AppRoutes.productDetailPath(item.relatedProductId!);
    }

    if (item.type == NotificationType.chat && item.relatedChatRoomId != null) {
      if (user?.isStaff == true) {
        return AppRoutes.staffChatRoomPath(item.relatedChatRoomId!);
      }
      return AppRoutes.chatRoomPath(item.relatedChatRoomId!);
    }

    return null;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity item;
  final VoidCallback onTap;

  const _NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.type) {
      NotificationType.order => (Icons.inventory_2_outlined, AppColors.primary),
      NotificationType.product => (
        Icons.stacked_line_chart_rounded,
        AppColors.secondary,
      ),
      NotificationType.chat => (
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF7C3AED),
      ),
      NotificationType.system => (Icons.sync_rounded, AppColors.warning),
      NotificationType.promotion => (Icons.local_offer_outlined, Colors.pink),
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !item.isRead
                  ? color.withValues(alpha: 0.32)
                  : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            key: Key('notificationUnreadDot-${item.id}'),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _NotificationMetaChip(
                          label: _formatCategory(item.type),
                          color: color,
                        ),
                        _NotificationMetaChip(
                          label: _formatTime(item.createdAt),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategory(NotificationType type) => switch (type) {
    NotificationType.order => 'Đơn hàng',
    NotificationType.product => 'Sản phẩm',
    NotificationType.chat => 'Tin nhắn',
    NotificationType.system => 'Hệ thống',
    NotificationType.promotion => 'Khuyến mãi',
  };

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    return '${diff.inDays} ngày trước';
  }
}

class _NotificationMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _NotificationMetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
