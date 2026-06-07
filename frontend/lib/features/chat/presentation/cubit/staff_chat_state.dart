part of 'staff_chat_cubit.dart';

enum StaffChatStatus { initial, loading, success, empty, failure }

class StaffChatState extends Equatable {
  final StaffChatStatus status;
  final List<StaffChatRoom> rooms;
  final StaffChatRoomFilter filter;
  final String query;
  final String? updatingRoomId;
  final String? errorMessage;
  final String? actionMessage;
  final String? actionErrorMessage;

  const StaffChatState({
    this.status = StaffChatStatus.initial,
    this.rooms = const [],
    this.filter = StaffChatRoomFilter.open,
    this.query = '',
    this.updatingRoomId,
    this.errorMessage,
    this.actionMessage,
    this.actionErrorMessage,
  });

  int get openCount => rooms.where((room) => !room.isClosed).length;

  int get closedCount => rooms.where((room) => room.isClosed).length;

  StaffChatState copyWith({
    StaffChatStatus? status,
    List<StaffChatRoom>? rooms,
    StaffChatRoomFilter? filter,
    String? query,
    String? updatingRoomId,
    bool clearUpdatingRoomId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionMessage,
    String? actionErrorMessage,
    bool clearActionMessage = false,
  }) {
    return StaffChatState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      updatingRoomId: clearUpdatingRoomId
          ? null
          : updatingRoomId ?? this.updatingRoomId,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
      actionErrorMessage: clearActionMessage
          ? null
          : actionErrorMessage ?? this.actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rooms,
    filter,
    query,
    updatingRoomId,
    errorMessage,
    actionMessage,
    actionErrorMessage,
  ];
}
