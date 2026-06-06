import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';
import 'package:marinelink/features/notifications/domain/notification_repository.dart';
import 'package:marinelink/features/notifications/presentation/bloc/notification_cubit.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late NotificationRepository notificationRepository;
  late NotificationCubit notificationCubit;

  final tNotifications = [
    NotificationEntity(
      id: '1',
      type: NotificationType.order,
      title: 'Title 1',
      message: 'Message 1',
      createdAt: DateTime.now(),
      isRead: false,
    ),
  ];

  setUp(() {
    notificationRepository = MockNotificationRepository();
    notificationCubit = NotificationCubit(notificationRepository: notificationRepository);
  });

  tearDown(() {
    notificationCubit.close();
  });

  test('initial state is correct', () {
    expect(notificationCubit.state, const NotificationState());
  });

  blocTest<NotificationCubit, NotificationState>(
    'emits [loading, success] when loadNotifications is successful',
    build: () {
      when(() => notificationRepository.getNotifications()).thenAnswer(
        (_) async => ApiResponse(success: true, message: 'OK', data: tNotifications),
      );
      return notificationCubit;
    },
    act: (cubit) => cubit.loadNotifications(),
    expect: () => [
      const NotificationState(status: NotificationStatus.loading),
      NotificationState(
        status: NotificationStatus.success,
        notifications: tNotifications,
      ),
    ],
  );

  blocTest<NotificationCubit, NotificationState>(
    'emits [loading, failure] when loadNotifications fails',
    build: () {
      when(() => notificationRepository.getNotifications()).thenAnswer(
        (_) async => const ApiResponse(success: false, message: 'Error', data: null),
      );
      return notificationCubit;
    },
    act: (cubit) => cubit.loadNotifications(),
    expect: () => [
      const NotificationState(status: NotificationStatus.loading),
      const NotificationState(status: NotificationStatus.failure),
    ],
  );

  blocTest<NotificationCubit, NotificationState>(
    'updates notification read state when markAsRead is successful',
    seed: () => NotificationState(
      status: NotificationStatus.success,
      notifications: tNotifications,
    ),
    build: () {
      when(() => notificationRepository.markAsRead('1')).thenAnswer(
        (_) async => const ApiResponse(success: true, message: 'OK'),
      );
      return notificationCubit;
    },
    act: (cubit) => cubit.markAsRead('1'),
    expect: () => [
      NotificationState(
        status: NotificationStatus.success,
        notifications: [tNotifications[0].copyWith(isRead: true)],
      ),
    ],
  );
}
