import '../../../core/api/api_response.dart';
import '../domain/notification.dart';
import '../domain/notification_broadcast.dart';
import '../domain/notification_repository.dart';

class NotificationMockRepository implements NotificationRepository {
  static final List<NotificationEntity> _items = [
    NotificationEntity(
      id: 'noti-001',
      type: NotificationType.order,
      title: 'Đơn hàng ML-20260528-0001 đã được xác nhận',
      message: 'Kho Cà Mau đã xác nhận 120kg mực khô giao vào sáng mai.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      relatedOrderId: 'order-001',
    ),
    NotificationEntity(
      id: 'noti-002',
      type: NotificationType.product,
      title: 'Giá tôm khô đã cập nhật theo bậc mới',
      message: 'Mốc giá 5kg và 10kg đã được điều chỉnh cho kênh đại lý.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      relatedProductId: 'prod-002',
    ),
    NotificationEntity(
      id: 'noti-003',
      type: NotificationType.chat,
      title: 'Nhân viên hỗ trợ đã phản hồi chat',
      message: 'Bạn có tin nhắn mới trong phòng chat về đơn hàng đang giao.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      relatedChatRoomId: 'bon-bot',
    ),
    NotificationEntity(
      id: 'noti-004',
      type: NotificationType.system,
      title: 'Hệ thống đã đồng bộ dữ liệu mới',
      message: 'Thông tin đơn hàng và kho đã được cập nhật cho tài khoản.',
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
      title: 'Lịch nghỉ lễ kho Cà Mau',
      body: 'Kho Cà Mau nghỉ ngày 30/4 và 1/5, đơn hàng sẽ giao lại từ 2/5.',
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
      message: 'Đã gửi thông báo đến các đại lý',
      data: broadcast,
    );
  }

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _broadcasts.removeWhere((b) => b.broadcastId == broadcastId);
    return const ApiResponse(success: true, message: 'Đã xóa thông báo');
  }
}
