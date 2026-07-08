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
import 'package:marinelink/features/notifications/domain/notification_broadcast.dart';
import 'package:marinelink/features/notifications/domain/notification_repository.dart';
import 'package:marinelink/features/notifications/presentation/bloc/broadcast_cubit.dart';
import 'package:marinelink/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:marinelink/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRepo implements NotificationRepository {
  final List<NotificationBroadcast> broadcasts;
  final List<Map<String, String>> created = [];
  final List<String> deleted = [];

  _FakeRepo({this.broadcasts = const []});

  @override
  Future<ApiResponse<List<NotificationBroadcast>>> getBroadcasts() async =>
      ApiResponse(success: true, data: List.of(broadcasts));

  @override
  Future<ApiResponse<NotificationBroadcast>> createBroadcast({
    required String title,
    required String body,
  }) async {
    created.add({'title': title, 'body': body});
    return ApiResponse(
      success: true,
      data: NotificationBroadcast(
        broadcastId: 'bcast-new',
        title: title,
        body: body,
        createdAt: DateTime.utc(2026, 5, 28),
        recipientCount: 3,
      ),
    );
  }

  @override
  Future<ApiResponse<void>> deleteBroadcast(String broadcastId) async {
    deleted.add(broadcastId);
    return const ApiResponse(success: true);
  }

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

class _MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

const _staff = User(
  id: 'staff-001',
  fullName: 'Nhân viên',
  email: 'staff@marinelink.demo',
  phone: '0901000002',
  status: 'ACTIVE',
  roles: ['STAFF'],
);

void _register(_FakeRepo repo) {
  sl.registerLazySingleton<NotificationRepository>(() => repo);
  sl.registerFactory<NotificationCubit>(
    () =>
        NotificationCubit(notificationRepository: sl<NotificationRepository>()),
  );
  sl.registerFactory<BroadcastCubit>(
    () => BroadcastCubit(notificationRepository: sl<NotificationRepository>()),
  );
}

AuthBloc _authBloc() {
  final bloc = _MockAuthBloc();
  when(
    () => bloc.state,
  ).thenReturn(const AuthAuthenticated(user: _staff, token: 'token'));
  when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
  return bloc;
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  _register(repo);
  final router = GoRouter(
    initialLocation: '/staff/notifications',
    routes: [
      GoRoute(
        path: '/staff/notifications',
        builder: (context, state) =>
            const NotificationsScreen(canManageBroadcasts: true),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          BlocProvider<AuthBloc>.value(value: _authBloc(), child: child!),
    ),
  );
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.allowReassignment = true;
  });

  tearDown(() async => sl.reset());

  testWidgets('staff sees broadcast composer and existing history', (
    tester,
  ) async {
    final repo = _FakeRepo(
      broadcasts: [
        NotificationBroadcast(
          broadcastId: 'bcast-1',
          title: 'Lịch nghỉ lễ',
          body: 'Kho nghỉ 30/4.',
          createdAt: DateTime.utc(2026, 5, 28),
          recipientCount: 12,
        ),
      ],
    );

    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('broadcastComposer')), findsOneWidget);
    expect(
      find.byKey(const Key('broadcastHistoryItem-bcast-1')),
      findsOneWidget,
    );
    expect(find.text('Lịch nghỉ lễ'), findsOneWidget);
  });

  testWidgets('validation blocks empty submit', (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('broadcastSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('submitting a broadcast sends it and clears the form', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('broadcastTitleField')),
      'Bảo trì hệ thống',
    );
    await tester.enterText(
      find.byKey(const Key('broadcastBodyField')),
      'Bảo trì lúc 22h.',
    );
    await tester.tap(find.byKey(const Key('broadcastSubmitButton')));
    await tester.pumpAndSettle();

    expect(repo.created.single, {
      'title': 'Bảo trì hệ thống',
      'body': 'Bảo trì lúc 22h.',
    });
    // New broadcast now appears in history.
    expect(
      find.byKey(const Key('broadcastHistoryItem-bcast-new')),
      findsOneWidget,
    );
    // Form cleared.
    final titleField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('broadcastTitleField')),
        matching: find.byType(TextField),
      ),
    );
    expect(titleField.controller?.text, isEmpty);
  });

  testWidgets('deleting a broadcast after confirm removes it', (tester) async {
    final repo = _FakeRepo(
      broadcasts: [
        NotificationBroadcast(
          broadcastId: 'bcast-1',
          title: 'Lịch nghỉ lễ',
          body: 'Kho nghỉ 30/4.',
          createdAt: DateTime.utc(2026, 5, 28),
          recipientCount: 12,
        ),
      ],
    );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('broadcastDeleteButton-bcast-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('broadcastDeleteConfirmButton')));
    await tester.pumpAndSettle();

    expect(repo.deleted, contains('bcast-1'));
    expect(
      find.byKey(const Key('broadcastHistoryItem-bcast-1')),
      findsNothing,
    );
  });
}
