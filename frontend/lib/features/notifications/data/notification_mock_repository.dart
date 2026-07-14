import 'package:marinelink/core/constants/app_strings.dart';
import '../../../core/api/api_response.dart';
import '../domain/notification.dart';
import '../domain/notification_broadcast.dart';
import '../domain/notification_repository.dart';

class NotificationMockRepository implements NotificationRepository {
  static final List<NotificationEntity> _items = [
    NotificationEntity(
      id: 'noti-001',
      type: NotificationType.order,
      title: AppStrings.orderConfirmedNotificationTitle,
      message: AppStrings.warehouseNotificationBody,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      relatedOrderId: 'order-001',
    ),
    NotificationEntity(
      id: 'noti-002',
      type: NotificationType.product,
      title: AppStrings.priceUpdatedNotificationTitle,
      message: AppStrings.priceNotificationBody,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      relatedProductId: 'prod-002',
    ),
    NotificationEntity(
      id: 'noti-003',
      type: NotificationType.chat,
      title: AppStrings.chatReplyNotificationTitle,
      message: AppStrings.chatNotificationBody,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      relatedChatRoomId: 'bon-bot',
    ),
    NotificationEntity(
      id: 'noti-004',
      type: NotificationType.system,
      title: AppStrings.systemSyncNotificationTitle,
      message: AppStrings.systemNotificationBody,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final filtered = isRead == null
        ? _items
        : _items.where((item) => item.isRead == isRead).toList();

    return ApiResponse(
      success: true,
      message: 'OK',
      data: filtered.skip(page * size).take(size).toList(),
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return const ApiResponse(success: true, message: 'Marked as read');
  }

  static final List<NotificationBroadcast> _broadcasts = [
    NotificationBroadcast(
      broadcastId: 'bcast-001',
      title: AppStrings.holidayWarehouseTitle,
      body: AppStrings.holidayWarehouseBody,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      recipientCount: 12,
    ),
  ];

  @override
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiResponse(
      success: true,
      message: 'OK',
      data: List.unmodifiable(_broadcasts),
    );
  }

  @override
  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final broadcast = NotificationBroadcast(
      broadcastId: 'bcast-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      body: body.trim(),
      createdAt: DateTime.now(),
      recipientCount: 12,
    );
    _broadcasts.insert(0, broadcast);
    return ApiResponse(
      success: true,
      message: AppStrings.notificationSentToDealers,
      data: broadcast,
    );
  }

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _broadcasts.removeWhere((b) => b.broadcastId == broadcastId);
    return const ApiResponse(
      success: true,
      message: AppStrings.notificationDeleted,
    );
  }
}
