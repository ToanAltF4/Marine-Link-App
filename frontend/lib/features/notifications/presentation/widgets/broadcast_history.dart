import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/notification_broadcast.dart';
import '../bloc/broadcast_cubit.dart';

/// Lịch sử các thông báo đã gửi tới đại lý (trạng thái tải/rỗng/danh sách).
class BroadcastHistory extends StatelessWidget {
  final BroadcastState state;

  const BroadcastHistory({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == BroadcastStatus.loading) {
      return const Padding(
        key: Key('broadcastHistoryLoading'),
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.broadcasts.isEmpty) {
      return Text(
        key: const Key('broadcastHistoryEmpty'),
        AppStrings.notificationHistoryEmpty,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      key: const Key('broadcastHistory'),
      children: [
        for (final item in state.broadcasts) ...[
          BroadcastHistoryTile(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Một dòng lịch sử thông báo kèm nút xóa có xác nhận.
class BroadcastHistoryTile extends StatelessWidget {
  final NotificationBroadcast item;

  const BroadcastHistoryTile({super.key, required this.item});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteNotificationTitle),
        content: Text(AppStrings.deleteBroadcastMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            key: const Key('broadcastDeleteConfirmButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<BroadcastCubit>().deleteBroadcast(item.broadcastId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('broadcastHistoryItem-${item.broadcastId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.broadcastMeta(
                    _formatDateTime(item.createdAt),
                    item.recipientCount,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('broadcastDeleteButton-${item.broadcastId}'),
            tooltip: AppStrings.deleteNotification,
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
