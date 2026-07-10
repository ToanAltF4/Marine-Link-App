import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/notification.dart';
import '../../domain/notification_display_service.dart';
import '../../domain/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  final NotificationDisplayService notificationDisplayService;

  NotificationCubit({
    required this.notificationRepository,
    this.notificationDisplayService = const NoopNotificationDisplayService(),
  }) : super(const NotificationState());

  Future<void> loadNotifications({
    NotificationReadFilter? filter,
    bool showLoading = true,
  }) async {
    final nextFilter = filter ?? state.filter;
    if (showLoading) {
      emit(
        state.copyWith(
          status: NotificationStatus.loading,
          filter: nextFilter,
          clearError: true,
        ),
      );
    }

    try {
      final response = await notificationRepository.getNotifications(
        isRead: _readValue(nextFilter),
      );

      if (response.success) {
        final items = response.data ?? const <NotificationEntity>[];
        emit(
          state.copyWith(
            status: items.isEmpty
                ? NotificationStatus.empty
                : NotificationStatus.success,
            filter: nextFilter,
            notifications: items,
            clearError: true,
          ),
        );
        await notificationDisplayService.syncNewNotifications(items);
        return;
      }

      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          filter: nextFilter,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: 'Không tải được danh sách thông báo.',
          ),
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          filter: nextFilter,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Không tải được danh sách thông báo.',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          filter: nextFilter,
          errorMessage: 'Đã xảy ra lỗi khi tải thông báo.',
        ),
      );
    }
  }

  Future<void> changeFilter(NotificationReadFilter filter) {
    return loadNotifications(filter: filter);
  }

  Future<void> markAsRead(String id) async {
    final response = await notificationRepository.markAsRead(id);
    if (!response.success) {
      return;
    }

    final updatedList = state.notifications.map((item) {
      return item.id == id ? item.copyWith(isRead: true) : item;
    }).toList();

    emit(state.copyWith(notifications: updatedList, clearError: true));
  }

  bool? _readValue(NotificationReadFilter filter) {
    return switch (filter) {
      NotificationReadFilter.all => null,
      NotificationReadFilter.unread => false,
      NotificationReadFilter.read => true,
    };
  }
}
