part of 'notification_cubit.dart';

enum NotificationStatus { initial, loading, success, empty, failure }

enum NotificationReadFilter { all, unread, read }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final NotificationReadFilter filter;
  final List<NotificationEntity> notifications;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.filter = NotificationReadFilter.all,
    this.notifications = const [],
    this.errorMessage,
  });

  List<NotificationEntity> get unreadNotifications =>
      notifications.where((item) => !item.isRead).toList();

  List<NotificationEntity> get readNotifications =>
      notifications.where((item) => item.isRead).toList();

  NotificationState copyWith({
    NotificationStatus? status,
    NotificationReadFilter? filter,
    List<NotificationEntity>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, filter, notifications, errorMessage];
}
