import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:marinelink/features/chat/domain/chat_repository.dart';
import 'package:marinelink/features/chat/presentation/cubit/staff_chat_cubit.dart';

class _FakeRepo implements ChatRepository {
  Future<ApiResponse<List<StaffChatRoom>>> Function({
    StaffChatRoomFilter filter,
    String? query,
  })
  staffRoomsResponder;
  Future<ApiResponse<StaffChatRoom>> Function({
    required String roomId,
    required bool isClosed,
  })
  statusResponder;
  Future<ApiResponse<StaffChatComplaint>> Function({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  })
  complaintResponder;

  _FakeRepo({
    Future<ApiResponse<List<StaffChatRoom>>> Function({
      StaffChatRoomFilter filter,
      String? query,
    })?
    staffRoomsResponder,
    Future<ApiResponse<StaffChatRoom>> Function({
      required String roomId,
      required bool isClosed,
    })?
    statusResponder,
    Future<ApiResponse<StaffChatComplaint>> Function({
      required String roomId,
      required String title,
      required String description,
      String? messageId,
    })?
    complaintResponder,
  }) : staffRoomsResponder =
           staffRoomsResponder ??
           (({filter = StaffChatRoomFilter.open, query}) async =>
               ApiResponse(success: true, message: 'OK', data: [_room])),
       statusResponder =
           statusResponder ??
           (({required roomId, required isClosed}) async => ApiResponse(
             success: true,
             message: 'OK',
             data: _room.copyWith(isClosed: isClosed),
           )),
       complaintResponder =
           complaintResponder ??
           (({
             required roomId,
             required title,
             required description,
             messageId,
           }) async => ApiResponse(
             success: true,
             message: 'OK',
             data: StaffChatComplaint(
               id: 'complaint-001',
               roomId: roomId,
               title: title,
               description: description,
               status: 'OPEN',
             ),
           ));

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) async =>
      const ApiResponse(
        success: true,
        message: 'OK',
        data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
      );

  @override
  Future<ApiResponse<ChatThread>> getMyRoom() async => const ApiResponse(
    success: true,
    message: 'OK',
    data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
  );

  @override
  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId) async =>
      const ApiResponse(
        success: true,
        message: 'OK',
        data: ChatThread(roomId: 'room-001', isClosed: false, messages: []),
      );

  @override
  Future<ApiResponse<List<ChatRoomSummary>>> getMyRooms() async =>
      const ApiResponse(success: true, message: 'OK', data: []);

  @override
  Future<ApiResponse<ChatThread>> createRoom() async =>
      const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  }) => staffRoomsResponder(filter: filter, query: query);

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) async => const ApiResponse(success: false, message: 'Unsupported');

  @override
  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  }) => statusResponder(roomId: roomId, isClosed: isClosed);

  @override
  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) => complaintResponder(
    roomId: roomId,
    title: title,
    description: description,
    messageId: messageId,
  );
}

final _room = StaffChatRoom(
  roomId: 'room-001',
  customer: const StaffChatCustomer(
    id: 'user-001',
    fullName: 'Dai ly A',
    email: 'daily-a@demo.test',
    phone: '0901000001',
  ),
  assignedStaff: const StaffChatAssignee(id: 'staff-001', fullName: 'Staff'),
  isClosed: false,
  lastMessageAt: DateTime.utc(2026, 5, 28, 8, 30),
  messageCount: 2,
  summary: 'Dai ly: Can ho tro',
);

void main() {
  blocTest<StaffChatCubit, StaffChatState>(
    'emits [loading, success] when rooms exist',
    build: () => StaffChatCubit(repository: _FakeRepo()),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.loading,
      ),
      isA<StaffChatState>()
          .having((state) => state.status, 'status', StaffChatStatus.success)
          .having((state) => state.rooms.length, 'rooms', 1),
    ],
  );

  blocTest<StaffChatCubit, StaffChatState>(
    'emits [loading, empty] when no rooms match',
    build: () => StaffChatCubit(
      repository: _FakeRepo(
        staffRoomsResponder:
            ({filter = StaffChatRoomFilter.open, query}) async =>
                const ApiResponse(success: true, message: 'OK', data: []),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.loading,
      ),
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.empty,
      ),
    ],
  );

  blocTest<StaffChatCubit, StaffChatState>(
    'setFilter reloads rooms with selected filter',
    build: () => StaffChatCubit(repository: _FakeRepo()),
    act: (cubit) => cubit.setFilter(StaffChatRoomFilter.closed),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.filter,
        'filter',
        StaffChatRoomFilter.closed,
      ),
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.loading,
      ),
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.success,
      ),
    ],
  );

  blocTest<StaffChatCubit, StaffChatState>(
    'setRoomClosed updates status and reloads',
    seed: () => StaffChatState(status: StaffChatStatus.success, rooms: [_room]),
    build: () => StaffChatCubit(repository: _FakeRepo()),
    act: (cubit) => cubit.setRoomClosed('room-001', true),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.updatingRoomId,
        'updatingRoomId',
        'room-001',
      ),
      isA<StaffChatState>().having(
        (state) => state.actionMessage,
        'actionMessage',
        isNotEmpty,
      ),
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.loading,
      ),
      isA<StaffChatState>().having(
        (state) => state.status,
        'status',
        StaffChatStatus.success,
      ),
    ],
  );

  blocTest<StaffChatCubit, StaffChatState>(
    'createComplaint emits success message',
    seed: () => StaffChatState(status: StaffChatStatus.success, rooms: [_room]),
    build: () => StaffChatCubit(repository: _FakeRepo()),
    act: (cubit) => cubit.createComplaint(
      roomId: 'room-001',
      title: 'Giao thieu hang',
      description: 'Khach bao giao thieu hang',
    ),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.updatingRoomId,
        'updatingRoomId',
        'room-001',
      ),
      isA<StaffChatState>().having(
        (state) => state.actionMessage,
        'actionMessage',
        isNotEmpty,
      ),
    ],
  );

  blocTest<StaffChatCubit, StaffChatState>(
    'createComplaint rejects blank title and description',
    build: () => StaffChatCubit(repository: _FakeRepo()),
    act: (cubit) =>
        cubit.createComplaint(roomId: 'room-001', title: ' ', description: ' '),
    expect: () => [
      isA<StaffChatState>().having(
        (state) => state.actionErrorMessage,
        'actionErrorMessage',
        isNotEmpty,
      ),
    ],
  );
}
