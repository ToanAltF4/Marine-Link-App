import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';
import 'package:marinelink/features/notifications/domain/notification.dart';
import 'package:marinelink/features/notifications/domain/notification_repository.dart';
import 'package:marinelink/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:marinelink/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:mocktail/mocktail.dart';

class _FakeNotificationRepository implements NotificationRepository {
  List<NotificationEntity> items;
  bool failLoad;
  final Completer<ApiResponse<List<NotificationEntity>>>? loadCompleter;
  final List<bool?> requestedReadFilters = [];
  final List<String> markedIds = [];

  _FakeNotificationRepository({
    this.items = const [],
    this.failLoad = false,
    this.loadCompleter,
  });

  @override
  Future<ApiResponse<List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
    bool? isRead,
  }) async {
    requestedReadFilters.add(isRead);
    if (loadCompleter != null) {
      return loadCompleter!.future;
    }
    if (failLoad) {
      return const ApiResponse(
        success: false,
        message: 'Không tải được thông báo.',
      );
    }
    final filtered = isRead == null
        ? items
        : items.where((item) => item.isRead == isRead).toList();
    return ApiResponse(success: true, message: 'OK', data: filtered);
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    markedIds.add(id);
    items = items
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    return const ApiResponse(success: true, message: 'OK');
  }
}

class _MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

const _buyer = User(
  id: 'user-001',
  fullName: 'Đại lý A',
  email: 'daily-a@marinelink.demo',
  phone: '0901000001',
  status: 'ACTIVE',
  roles: ['USER'],
);

const _staff = User(
  id: 'staff-001',
  fullName: 'Nhân viên',
  email: 'staff@marinelink.demo',
  phone: '0901000002',
  status: 'ACTIVE',
  roles: ['STAFF'],
);

final _notifications = [
  NotificationEntity(
    id: 'noti-order',
    type: NotificationType.order,
    title: 'Đơn hàng đã xác nhận',
    message: 'Đơn ML-20260528-0001 đã được xác nhận.',
    createdAt: DateTime.utc(2026, 5, 28, 8, 30),
    relatedOrderId: 'order-001',
  ),
  NotificationEntity(
    id: 'noti-product',
    type: NotificationType.product,
    title: 'Giá sản phẩm đã đổi',
    message: 'Tôm khô đã có giá mới.',
    createdAt: DateTime.utc(2026, 5, 28, 8, 10),
    relatedProductId: 'prod-002',
  ),
  NotificationEntity(
    id: 'noti-chat',
    type: NotificationType.chat,
    title: 'Chat có phản hồi mới',
    message: 'Nhân viên đã trả lời câu hỏi của bạn.',
    createdAt: DateTime.utc(2026, 5, 28, 7, 30),
    isRead: true,
    relatedChatRoomId: 'room-001',
  ),
];

void _registerNotificationRepo(_FakeNotificationRepository repository) {
  sl.registerLazySingleton<NotificationRepository>(() => repository);
  sl.registerFactory<NotificationCubit>(
    () =>
        NotificationCubit(notificationRepository: sl<NotificationRepository>()),
  );
}

AuthBloc _authBlocFor(User user) {
  final bloc = _MockAuthBloc();
  when(
    () => bloc.state,
  ).thenReturn(AuthAuthenticated(user: user, token: 'token'));
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Order Detail ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => Scaffold(
          body: Text('Product Detail ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) => Scaffold(
          body: Text('Buyer Chat ${state.pathParameters['roomId']}'),
        ),
      ),
      GoRoute(
        path: '/staff/chat/:roomId',
        builder: (context, state) => Scaffold(
          body: Text('Staff Chat ${state.pathParameters['roomId']}'),
        ),
      ),
    ],
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeNotificationRepository repository,
  User user = _buyer,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  _registerNotificationRepo(repository);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: _router(),
      builder: (context, child) => BlocProvider<AuthBloc>.value(
        value: _authBlocFor(user),
        child: child!,
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.allowReassignment = true;
  });

  tearDown(() async => sl.reset());

  testWidgets('renders loading state while notifications are loading', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<List<NotificationEntity>>>();

    await _pumpScreen(
      tester,
      repository: _FakeNotificationRepository(loadCompleter: completer),
    );
    await tester.pump();

    expect(find.byKey(const Key('notificationsLoading')), findsOneWidget);

    completer.complete(
      ApiResponse(success: true, message: 'OK', data: _notifications),
    );
  });

  testWidgets('renders error state and retries loading', (tester) async {
    final repository = _FakeNotificationRepository(failLoad: true);

    await _pumpScreen(tester, repository: repository);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('notificationsError')), findsOneWidget);
    expect(find.text('Không tải được thông báo.'), findsOneWidget);

    repository.failLoad = false;
    repository.items = _notifications;
    await tester.tap(find.byKey(const Key('appErrorStateRetryButton')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Đơn hàng đã xác nhận'), findsOneWidget);
  });

  testWidgets('renders empty state when no notification exists', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      repository: _FakeNotificationRepository(items: const []),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('notificationsEmpty')), findsOneWidget);
    expect(find.text('Chưa có thông báo phù hợp.'), findsOneWidget);
  });

  testWidgets('filters unread notifications and marks order as read on tap', (
    tester,
  ) async {
    final repository = _FakeNotificationRepository(items: _notifications);

    await _pumpScreen(tester, repository: repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('Đơn hàng đã xác nhận'), findsOneWidget);
    expect(find.text('Chat có phản hồi mới'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('notificationsReadFilter')),
            matching: find.text('Chưa đọc'),
          )
          .first,
    );
    await tester.pump();
    await tester.pump();

    expect(repository.requestedReadFilters.last, isFalse);
    expect(find.text('Chat có phản hồi mới'), findsNothing);

    await tester.tap(find.text('Đơn hàng đã xác nhận'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, contains('noti-order'));
    expect(find.text('Order Detail order-001'), findsOneWidget);
  });

  testWidgets('opens staff chat route for staff chat notifications', (
    tester,
  ) async {
    final repository = _FakeNotificationRepository(items: _notifications);

    await _pumpScreen(tester, repository: repository, user: _staff);
    await tester.pump();
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('notificationsScrollView')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat có phản hồi mới'));
    await tester.pumpAndSettle();

    expect(find.text('Staff Chat room-001'), findsOneWidget);
  });
}
