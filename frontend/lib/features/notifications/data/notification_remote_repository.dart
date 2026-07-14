import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/notification.dart';
import '../domain/notification_broadcast.dart';
import '../domain/notification_repository.dart';
import 'notification_dto.dart';

class NotificationRemoteRepository implements NotificationRepository {
  final ApiClient apiClient;

  NotificationRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'size': size};
    if (isRead != null) {
      queryParameters['isRead'] = isRead;
    }

    return await apiClient.get<List<NotificationEntity>>(
      ApiEndpoints.notifications,
      queryParameters: queryParameters,
      fromJson: notificationsFromJson,
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    return await apiClient.put<void>(
      ApiEndpoints.notificationRead(id),
      fromJson: (_) {},
    );
  }

  @override
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts() async {
    return await apiClient.get<List<NotificationBroadcast>>(
      ApiEndpoints.notificationBroadcasts,
      fromJson: broadcastsFromJson,
    );
  }

  @override
  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  }) async {
    return await apiClient.post<NotificationBroadcast>(
      ApiEndpoints.notifications,
      data: {'title': title, 'body': body},
      fromJson: broadcastFromJson,
    );
  }

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async {
    await apiClient.delete(
      ApiEndpoints.notificationBroadcastDetail(broadcastId),
    );
    return const ApiResponse(success: true);
  }
}
