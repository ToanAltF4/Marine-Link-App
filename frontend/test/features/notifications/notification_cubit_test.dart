import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';
import 'package:marinelink/features/notifications/domain/notification_broadcast.dart';
import 'package:marinelink/features/notifications/domain/notification_display_service.dart';
import 'package:marinelink/features/notifications/domain/notification_repository.dart';
import 'package:marinelink/features/notifications/presentation/bloc/notification_cubit.dart';

class _NotificationRepo implements NotificationRepository {
  List<NotificationEntity> items;
  bool fail;
  final List<bool?> requestedReadFilters = [];

  _NotificationRepo({required this.items, this.fail = false});

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    requestedReadFilters.add(isRead);
    if (fail) {
      return const ApiResponse(success: false, message: 'Lỗi tải thông báo.');
    }
    final data = isRead == null
        ? items
        : items.where((item) => item.isRead == isRead).toList();
    return ApiResponse(success: true, message: 'OK', data: data);
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    items = items
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    return const ApiResponse(success: true, message: 'OK');
  }

  @override
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts() async =>
      const ApiResponse(success: true, data: []);

  @override
  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  }) async => throw UnimplementedError();

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async =>
      const ApiResponse(success: true);
}

class _NotificationDisplayService implements NotificationDisplayService {
  final List<List<NotificationEntity>> syncedNotifications = [];
  var initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> syncNewNotifications(
    List<NotificationEntity> notifications,
  ) async {
    syncedNotifications.add(notifications);
  }
}

final _items = [
  NotificationEntity(
    id: 'noti-001',
    type: NotificationType.order,
    title: 'Đơn hàng',
    message: 'Đơn đã xác nhận.',
    createdAt: DateTime.utc(2026, 5, 28),
    relatedOrderId: 'order-001',
  ),
  NotificationEntity(
    id: 'noti-002',
    type: NotificationType.chat,
    title: 'Chat',
    message: 'Có phản hồi mới.',
    createdAt: DateTime.utc(2026, 5, 28),
    isRead: true,
    relatedChatRoomId: 'room-001',
  ),
];

void main() {
  test(
    'loadNotifications emits success and keeps unread/read groups',
    () async {
      final repo = _NotificationRepo(items: _items);
      final cubit = NotificationCubit(notificationRepository: repo);

      await cubit.loadNotifications();

      expect(cubit.state.status, NotificationStatus.success);
      expect(cubit.state.unreadNotifications, hasLength(1));
      expect(cubit.state.readNotifications, hasLength(1));
      expect(repo.requestedReadFilters.single, isNull);
    },
  );

  test(
    'loadNotifications syncs loaded items to device notifications',
    () async {
      final repo = _NotificationRepo(items: _items);
      final displayService = _NotificationDisplayService();
      final cubit = NotificationCubit(
        notificationRepository: repo,
        notificationDisplayService: displayService,
      );

      await cubit.loadNotifications();

      expect(displayService.syncedNotifications, [_items]);
    },
  );

  test('changeFilter loads unread notifications only', () async {
    final repo = _NotificationRepo(items: _items);
    final cubit = NotificationCubit(notificationRepository: repo);

    await cubit.changeFilter(NotificationReadFilter.unread);

    expect(cubit.state.filter, NotificationReadFilter.unread);
    expect(cubit.state.notifications, hasLength(1));
    expect(cubit.state.notifications.single.id, 'noti-001');
    expect(repo.requestedReadFilters.single, isFalse);
  });

  test('markAsRead updates local state', () async {
    final repo = _NotificationRepo(items: _items);
    final cubit = NotificationCubit(notificationRepository: repo);

    await cubit.loadNotifications();
    await cubit.markAsRead('noti-001');

    expect(cubit.state.notifications.first.isRead, isTrue);
  });

  test('loadNotifications emits failure with Vietnamese message', () async {
    final repo = _NotificationRepo(items: const [], fail: true);
    final cubit = NotificationCubit(notificationRepository: repo);

    await cubit.loadNotifications();

    expect(cubit.state.status, NotificationStatus.failure);
    expect(cubit.state.errorMessage, 'Lỗi tải thông báo.');
  });
}
