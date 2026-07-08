import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/app/theme/app_theme.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/chat_rooms_cubit.dart';
import 'package:marinelink/features/chat/presentation/screens/chat_rooms_list_screen.dart';

class _RoomsRepo implements ChatRepository {
  List<ChatRoomSummary> rooms;
  final String? newRoomId;
  int getMyRoomsCalls = 0;

  _RoomsRepo({this.rooms = const [], this.newRoomId});

  @override
  Future<ApiResponse<List<ChatRoomSummary>>> getMyRooms() async {
    getMyRoomsCalls++;
    return ApiResponse(success: true, message: 'OK', data: rooms);
  }

  @override
  Future<ApiResponse<ChatThread>> createRoom() async => newRoomId == null
      ? const ApiResponse(success: false, message: 'fail')
      : ApiResponse(
          success: true,
          message: 'OK',
          data: ChatThread(
            roomId: newRoomId!,
            isClosed: false,
            messages: const [],
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used');
}

Widget _wrap(GoRouter router) => MaterialApp.router(
  theme: AppTheme.light(),
  routerConfig: router,
);

GoRouter _router() => GoRouter(
  initialLocation: '/chat',
  routes: [
    GoRoute(path: '/chat', builder: (_, _) => const ChatRoomsListScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (_, state) =>
          Scaffold(body: Center(child: Text('THREAD ${state.pathParameters['id']}'))),
    ),
    GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('HOME'))),
  ],
);

void main() {
  tearDown(() async => sl.reset());

  testWidgets('lists chat history and opens a conversation on tap', (
    tester,
  ) async {
    sl.registerFactory<ChatRoomsCubit>(
      () => ChatRoomsCubit(
        repository: _RoomsRepo(
          rooms: const [
            ChatRoomSummary(roomId: 'r1', title: 'Xin chao shop', isClosed: false),
            ChatRoomSummary(roomId: 'r2', title: 'Khieu nai don', isClosed: true),
          ],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(_router()));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('chatRoomsList')), findsOneWidget);
    expect(find.text('Xin chao shop'), findsOneWidget);
    expect(find.text('Đã xử lý'), findsOneWidget); // closed room badge

    await tester.tap(find.byKey(const Key('chatRoomTile_r1')));
    await tester.pumpAndSettle();
    expect(find.text('THREAD r1'), findsOneWidget);
  });

  testWidgets('New chat button creates a room and opens it', (tester) async {
    sl.registerFactory<ChatRoomsCubit>(
      () => ChatRoomsCubit(repository: _RoomsRepo(newRoomId: 'fresh-room')),
    );

    await tester.pumpWidget(_wrap(_router()));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.byKey(const Key('chatNewChatButton')));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('THREAD fresh-room'), findsOneWidget);
  });

  testWidgets('refreshes chat history when returning from a thread', (
    tester,
  ) async {
    final repo = _RoomsRepo(
      rooms: const [
        ChatRoomSummary(roomId: 'r1', title: 'Xin chao shop', isClosed: false),
      ],
    );
    sl.registerFactory<ChatRoomsCubit>(() => ChatRoomsCubit(repository: repo));

    final router = _router();
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(repo.getMyRoomsCalls, 1);

    // Open the thread, then simulate backing out of it.
    await tester.tap(find.byKey(const Key('chatRoomTile_r1')));
    await tester.pumpAndSettle();
    expect(find.text('THREAD r1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Back on the list, the history was reloaded (no re-login needed).
    expect(find.byKey(const Key('chatRoomsList')), findsOneWidget);
    expect(repo.getMyRoomsCalls, 2);
  });
}
