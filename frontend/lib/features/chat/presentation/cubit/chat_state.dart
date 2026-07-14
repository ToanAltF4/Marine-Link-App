part of 'chat_cubit.dart';

enum ChatStatus { initial, loading, success, empty, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final String? roomId;
  final ChatThread? thread;
  final bool sending;
  final bool canRetrySend;
  final bool offlineFallback;

  /// True while a fresh conversation is being created (buyer "Đoạn chat mới").
  final bool creating;
  final String? errorMessage;
  final String? sendErrorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.roomId,
    this.thread,
    this.sending = false,
    this.canRetrySend = false,
    this.offlineFallback = false,
    this.creating = false,
    this.errorMessage,
    this.sendErrorMessage,
  });

  List<ChatMessage> get messages => thread?.messages ?? const [];

  ChatState copyWith({
    ChatStatus? status,
    String? roomId,
    ChatThread? thread,
    bool? sending,
    bool? canRetrySend,
    bool? offlineFallback,
    bool? creating,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? sendErrorMessage,
    bool clearSendErrorMessage = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      thread: thread ?? this.thread,
      sending: sending ?? this.sending,
      canRetrySend: canRetrySend ?? this.canRetrySend,
      offlineFallback: offlineFallback ?? this.offlineFallback,
      creating: creating ?? this.creating,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      sendErrorMessage: clearSendErrorMessage
          ? null
          : sendErrorMessage ?? this.sendErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    roomId,
    thread,
    sending,
    canRetrySend,
    offlineFallback,
    creating,
    errorMessage,
    sendErrorMessage,
  ];
}
