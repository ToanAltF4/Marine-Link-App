import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/chat_rooms_cubit.dart';

class _RoomsRepo implements ChatRepository {
  final List<ChatRoomSummary> rooms;
  final bool listOk;
  final String? newRoomId;

  _RoomsRepo({this.rooms = const [], this.listOk = true, this.newRoomId});

  @override
  Future<ApiResponse<List<ChatRoomSummary>>> getMyRooms() async => listOk
      ? ApiResponse(success: true, message: 'OK', data: rooms)
      : const ApiResponse(success: false, message: 'Không tải được lịch sử chat.');

  @override
  Future<ApiResponse<ChatThread>> createRoom() async => newRoomId == null
      ? const ApiResponse(success: false, message: 'Không tạo được.')
      : ApiResponse(
          success: true,
          message: 'OK',
          data: ChatThread(roomId: newRoomId!, isClosed: false, messages: const []),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used in test');
}

ChatRoomSummary _room(String id, String title, {bool closed = false}) =>
    ChatRoomSummary(roomId: id, title: title, isClosed: closed);

void main() {
  test('load emits success with rooms', () async {
    final cubit = ChatRoomsCubit(
      repository: _RoomsRepo(rooms: [_room('r1', 'Xin chao'), _room('r2', 'Hoi don')]),
    );
    await cubit.load();
    expect(cubit.state.status, ChatRoomsStatus.success);
    expect(cubit.state.rooms.length, 2);
    expect(cubit.state.rooms.first.title, 'Xin chao');
  });

  test('load emits empty when there are no rooms', () async {
    final cubit = ChatRoomsCubit(repository: _RoomsRepo(rooms: const []));
    await cubit.load();
    expect(cubit.state.status, ChatRoomsStatus.empty);
  });

  test('load emits failure on repository error', () async {
    final cubit = ChatRoomsCubit(repository: _RoomsRepo(listOk: false));
    await cubit.load();
    expect(cubit.state.status, ChatRoomsStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('createRoom returns the new room id', () async {
    final cubit = ChatRoomsCubit(repository: _RoomsRepo(newRoomId: 'new-room-1'));
    final id = await cubit.createRoom();
    expect(id, 'new-room-1');
    expect(cubit.state.creating, isFalse);
  });

  test('createRoom returns null and surfaces error on failure', () async {
    final cubit = ChatRoomsCubit(repository: _RoomsRepo(newRoomId: null));
    final id = await cubit.createRoom();
    expect(id, isNull);
    expect(cubit.state.errorMessage, isNotNull);
  });
}
