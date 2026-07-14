import 'notification.dart';

abstract class NotificationDisplayService {
  Future<void> initialize();

  Future<void> syncNewNotifications(List<NotificationEntity> notifications);
}

class NoopNotificationDisplayService implements NotificationDisplayService {
  const NoopNotificationDisplayService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncNewNotifications(
    List<NotificationEntity> notifications,
  ) async {}
}
