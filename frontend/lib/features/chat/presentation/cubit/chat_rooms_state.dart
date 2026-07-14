part of 'chat_rooms_cubit.dart';

enum ChatRoomsStatus { initial, loading, success, empty, failure }

class ChatRoomsState extends Equatable {
  final ChatRoomsStatus status;
  final List<ChatRoomSummary> rooms;
  final bool creating;
  final String? errorMessage;

  const ChatRoomsState({
    this.status = ChatRoomsStatus.initial,
    this.rooms = const [],
    this.creating = false,
    this.errorMessage,
  });

  ChatRoomsState copyWith({
    ChatRoomsStatus? status,
    List<ChatRoomSummary>? rooms,
    bool? creating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatRoomsState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      creating: creating ?? this.creating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, rooms, creating, errorMessage];
}
