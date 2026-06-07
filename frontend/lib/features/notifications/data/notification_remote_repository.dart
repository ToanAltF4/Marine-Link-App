import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/notification.dart';
import '../domain/notification_repository.dart';

class NotificationRemoteRepository implements NotificationRepository {
  final ApiClient apiClient;

  NotificationRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    return await apiClient.get<List<NotificationEntity>>(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'size': size,
        'isRead': isRead,
      },
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => _mapDtoToEntity(item)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    return await apiClient.put<void>(
      ApiEndpoints.notificationRead(id),
      fromJson: (_) {},
    );
  }

  NotificationEntity _mapDtoToEntity(Map<String, dynamic> json) {
    // Determine relatedId from various fields in DTO
    String? relatedId;
    if (json['relatedOrderId'] != null) {
      relatedId = json['relatedOrderId'].toString();
    } else if (json['relatedProductId'] != null) {
      relatedId = json['relatedProductId'].toString();
    } else if (json['relatedChatRoomId'] != null) {
      relatedId = json['relatedChatRoomId'].toString();
    }

    return NotificationEntity(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type']?.toString() ?? 'SYSTEM'),
      title: json['title'] ?? '',
      message: json['body'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isRead: json['read'] ?? false,
      relatedId: relatedId,
    );
  }
}
