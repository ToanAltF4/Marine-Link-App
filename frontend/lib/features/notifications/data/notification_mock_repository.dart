import '../../../core/api/api_response.dart';
import '../domain/notification.dart';
import '../domain/notification_repository.dart';

class NotificationMockRepository implements NotificationRepository {
  static final List<NotificationEntity> _items = [
    NotificationEntity(
      id: 'noti-001',
      type: NotificationType.order,
      title: 'Đơn hàng #OD2305 đã được xác nhận',
      message: 'Kho Cà Mau đã xác nhận 120kg mực khô giao vào sáng mai.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      relatedId: 'order-123', //id giả định
    ),
    NotificationEntity(
      id: 'noti-002',
      type: NotificationType.product,
      title: 'Giá tôm khô đã cập nhật theo tier mới',
      message: 'Mốc giá 5kg và 10kg đã được điều chỉnh cho kênh đại lý.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: false,
      relatedId: 'prod-456',
    ),
    NotificationEntity(
      id: 'noti-003',
      type: NotificationType.chat,
      title: 'Nhân viên hỗ trợ đã phản hồi chat',
      message: 'Bạn có tin nhắn mới trong phòng chat về đơn hàng đang giao.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      relatedId: 'bon-bot',
    ),
    NotificationEntity(
      id: 'noti-004',
      type: NotificationType.system,
      title: 'Lịch seed catalog đã đồng bộ',
      message: 'UI buyer đã đọc token mới từ Stitch kit Ocean B2B.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      relatedId: 'sys-789',
    ),
  ];

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    var filtered = _items;
    if (isRead != null) {
      filtered = _items.where((i) => i.isRead == isRead).toList();
    }

    return ApiResponse(
      success: true,
      message: 'OK',
      data: filtered,
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return const ApiResponse(success: true, message: 'Marked as read');
  }
}
