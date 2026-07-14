import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/domain/user.dart';
import '../../domain/notification.dart';
import '../bloc/notification_cubit.dart';
import 'notification_tile.dart';

/// Danh sách thông báo chia theo nhóm "Mới nhất" và "Trước đó".
class NotificationSections extends StatelessWidget {
  final NotificationState state;
  final User? user;

  const NotificationSections({
    super.key,
    required this.state,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final unreadItems = state.unreadNotifications;
    final readItems = state.readNotifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unreadItems.isNotEmpty) ...[
          const SectionTitle(title: AppStrings.latest),
          const SizedBox(height: 12),
          for (final item in unreadItems) ...[
            NotificationTile(
              key: Key('notificationTile-${item.id}'),
              item: item,
              onTap: () => _handleNotificationTap(context, item, user),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (readItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionTitle(title: AppStrings.earlier),
          const SizedBox(height: 12),
          for (final item in readItems) ...[
            NotificationTile(
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

/// Tiêu đề của một nhóm thông báo.
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

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
