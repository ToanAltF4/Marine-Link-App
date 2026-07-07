import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';
import 'package:marinelink/features/notifications/domain/notification_broadcast.dart';
import 'package:marinelink/features/notifications/domain/notification_repository.dart';
import 'package:marinelink/features/notifications/presentation/bloc/broadcast_cubit.dart';

class _FakeRepo implements NotificationRepository {
  List<NotificationBroadcast> broadcasts;
  bool failLoad;
  bool failCreate;
  ApiException? deleteThrows;
  final List<String> deletedIds = [];
  final List<Map<String, String>> created = [];

  _FakeRepo({
    this.broadcasts = const [],
    this.failLoad = false,
    this.failCreate = false,
    this.deleteThrows,
  });

  @override
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts() async {
    if (failLoad) {
      return const ApiResponse(success: false, message: 'Không tải được.');
    }
    return ApiResponse(success: true, data: broadcasts);
  }

  @override
  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  }) async {
    created.add({'title': title, 'body': body});
    if (failCreate) {
      return const ApiResponse(success: false, message: 'Không gửi được.');
    }
    final b = NotificationBroadcast(
      broadcastId: 'bcast-new',
      title: title,
      body: body,
      createdAt: DateTime.utc(2026, 5, 28),
      recipientCount: 3,
    );
    return ApiResponse(success: true, data: b);
  }

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async {
    deletedIds.add(broadcastId);
    if (deleteThrows != null) {
      throw deleteThrows!;
    }
    return const ApiResponse(success: true);
  }

  // Unused by BroadcastCubit.
  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async => const ApiResponse(success: true, data: []);

  @override
  Future<ApiResponse<void>> markAsRead(String id) async =>
      const ApiResponse(success: true);
}

NotificationBroadcast _b(String id) => NotificationBroadcast(
  broadcastId: id,
  title: 'Tiêu đề $id',
  body: 'Nội dung $id',
  createdAt: DateTime.utc(2026, 5, 28),
  recipientCount: 5,
);

void main() {
  test('loadBroadcasts emits ready with history', () async {
    final repo = _FakeRepo(broadcasts: [_b('1'), _b('2')]);
    final cubit = BroadcastCubit(notificationRepository: repo);

    await cubit.loadBroadcasts();

    expect(cubit.state.status, BroadcastStatus.ready);
    expect(cubit.state.broadcasts, hasLength(2));
  });

  test('loadBroadcasts emits failure with message', () async {
    final repo = _FakeRepo(failLoad: true);
    final cubit = BroadcastCubit(notificationRepository: repo);

    await cubit.loadBroadcasts();

    expect(cubit.state.status, BroadcastStatus.failure);
    expect(cubit.state.errorMessage, 'Không tải được.');
  });

  test('createBroadcast prepends new broadcast and returns true', () async {
    final repo = _FakeRepo(broadcasts: [_b('1')]);
    final cubit = BroadcastCubit(notificationRepository: repo);
    await cubit.loadBroadcasts();

    final ok = await cubit.createBroadcast(title: '  Mới  ', body: '  Body  ');

    expect(ok, isTrue);
    expect(cubit.state.broadcasts.first.broadcastId, 'bcast-new');
    expect(cubit.state.broadcasts, hasLength(2));
    expect(cubit.state.submitting, isFalse);
    expect(cubit.state.infoMessage, isNotNull);
    // Title/body trimmed before sending.
    expect(repo.created.single, {'title': 'Mới', 'body': 'Body'});
  });

  test('createBroadcast returns false and sets error on failure', () async {
    final repo = _FakeRepo(failCreate: true);
    final cubit = BroadcastCubit(notificationRepository: repo);

    final ok = await cubit.createBroadcast(title: 'T', body: 'B');

    expect(ok, isFalse);
    expect(cubit.state.errorMessage, 'Không gửi được.');
    expect(cubit.state.submitting, isFalse);
  });

  test('deleteBroadcast removes optimistically', () async {
    final repo = _FakeRepo(broadcasts: [_b('1'), _b('2')]);
    final cubit = BroadcastCubit(notificationRepository: repo);
    await cubit.loadBroadcasts();

    await cubit.deleteBroadcast('1');

    expect(repo.deletedIds, contains('1'));
    expect(cubit.state.broadcasts.map((b) => b.broadcastId), ['2']);
  });

  test('deleteBroadcast rolls back on error', () async {
    final repo = _FakeRepo(
      broadcasts: [_b('1'), _b('2')],
      deleteThrows: const ApiException(
        message: 'Không xóa được thông báo.',
        type: ApiExceptionType.server,
      ),
    );
    final cubit = BroadcastCubit(notificationRepository: repo);
    await cubit.loadBroadcasts();

    await cubit.deleteBroadcast('1');

    expect(cubit.state.broadcasts, hasLength(2));
    expect(cubit.state.errorMessage, 'Không xóa được thông báo.');
  });
}
