import '../../../core/api/api_response.dart';
import 'notification.dart';

abstract class NotificationRepository {
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  });

  Future<ApiResponse<void>> markAsRead(String id);
}
