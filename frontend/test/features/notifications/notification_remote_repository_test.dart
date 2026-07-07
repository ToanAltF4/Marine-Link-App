import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/notifications/data/notification_remote_repository.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';
import 'package:marinelink/features/notifications/domain/notification_broadcast.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late NotificationRemoteRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = NotificationRemoteRepository(apiClient: mockApiClient);
  });

  group('NotificationRemoteRepository', () {
    final tNotificationJson = {
      'id': 'noti-001',
      'type': 'ORDER',
      'title': 'Test Title',
      'body': 'Test Body',
      'relatedOrderId': 'order-123',
      'read': false,
      'createdAt': '2023-01-01T00:00:00Z',
    };

    test('getNotifications returns list of entities when successful', () async {
      when(
        () => mockApiClient.get<List<NotificationEntity>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as List<NotificationEntity> Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson([tNotificationJson]),
        );
      });

      final result = await repository.getNotifications();

      expect(result.success, true);
      expect(result.data?.length, 1);
      expect(result.data?[0].id, 'noti-001');
      expect(result.data?[0].type, NotificationType.order);
      expect(result.data?[0].relatedId, 'order-123');
    });

    test('markAsRead calls put endpoint', () async {
      when(
        () => mockApiClient.put<void>(any(), fromJson: any(named: 'fromJson')),
      ).thenAnswer(
        (_) async => const ApiResponse(success: true, message: 'OK'),
      );

      final result = await repository.markAsRead('noti-001');

      expect(result.success, true);
      verify(
        () => mockApiClient.put<void>(
          '/api/notifications/noti-001/read',
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('maps relatedIds correctly from DTO', () async {
      final productJson = {
        ...tNotificationJson,
        'type': 'PRODUCT',
        'relatedOrderId': null,
        'relatedProductId': 'prod-456',
      };

      when(
        () => mockApiClient.get<List<NotificationEntity>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as List<NotificationEntity> Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson([productJson]),
        );
      });

      final result = await repository.getNotifications();
      expect(result.data?[0].type, NotificationType.product);
      expect(result.data?[0].relatedId, 'prod-456');
    });

    test('getBroadcasts parses broadcast summaries', () async {
      when(
        () => mockApiClient.get<List<NotificationBroadcast>>(
          any(),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as List<NotificationBroadcast> Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson([
            {
              'broadcastId': 'bcast-1',
              'title': 'Bảo trì',
              'body': 'Nội dung',
              'createdBy': 'staff-1',
              'createdAt': '2026-05-28T08:30:00Z',
              'recipientCount': 4,
            },
          ]),
        );
      });

      final result = await repository.getBroadcasts();

      expect(result.success, true);
      expect(result.data?.single.broadcastId, 'bcast-1');
      expect(result.data?.single.recipientCount, 4);
      verify(
        () => mockApiClient.get<List<NotificationBroadcast>>(
          '/api/notifications/broadcasts',
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('createBroadcast posts title and body', () async {
      when(
        () => mockApiClient.post<NotificationBroadcast>(
          any(),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson]
                as NotificationBroadcast Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson({
            'broadcastId': 'bcast-new',
            'title': 'Bảo trì',
            'body': 'Nội dung',
            'createdAt': '2026-05-28T08:30:00Z',
            'recipientCount': 7,
          }),
        );
      });

      final result = await repository.createBroadcast(
        title: 'Bảo trì',
        body: 'Nội dung',
      );

      expect(result.data?.broadcastId, 'bcast-new');
      verify(
        () => mockApiClient.post<NotificationBroadcast>(
          '/api/notifications',
          data: {'title': 'Bảo trì', 'body': 'Nội dung'},
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('deleteBroadcast calls delete endpoint', () async {
      when(() => mockApiClient.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteBroadcast('bcast-1');

      expect(result.success, true);
      verify(
        () => mockApiClient.delete('/api/notifications/broadcasts/bcast-1'),
      ).called(1);
    });
  });
}
