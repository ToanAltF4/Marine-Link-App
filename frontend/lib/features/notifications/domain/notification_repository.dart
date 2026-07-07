import '../../../core/api/api_response.dart';
import 'notification.dart';
import 'notification_broadcast.dart';

abstract class NotificationRepository {
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  });

  Future<ApiResponse<void>> markAsRead(String id);

  // ── Admin/staff broadcasts ──────────────────────────────────────────────
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts();

  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  });

  Future<ApiResponse<void>> deleteBroadcast(String broadcastId);
}
