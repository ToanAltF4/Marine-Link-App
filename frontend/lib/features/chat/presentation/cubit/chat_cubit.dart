import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  final ChatRealtimeService? realtime;

  ChatRealtimeSubscription? _realtimeSub;
  String? _subscribedRoomId;

  ChatCubit({required this.repository, this.realtime})
    : super(const ChatState());

  /// Subscribe to live messages for [roomId]; append arrivals immediately.
  void _subscribeRealtime(String? roomId) {
    final service = realtime;
    if (service == null || roomId == null || roomId.isEmpty) return;
    if (_subscribedRoomId == roomId && _realtimeSub != null) return;
    _realtimeSub?.cancel();
    _subscribedRoomId = roomId;
    _realtimeSub = service.subscribeToRoom(roomId, _onRealtimeMessage);
  }

  void _onRealtimeMessage(ChatMessage message) {
    if (isClosed) return;
    if (message.roomId != state.roomId) return;
    final thread = state.thread;
    if (thread == null) return;
    // Dedupe: our own sent message is appended optimistically and also echoed
    // back over the socket.
    if (thread.messages.any((m) => m.id == message.id)) return;
    emit(
      state.copyWith(
        status: ChatStatus.success,
        thread: thread.copyWith(messages: [...thread.messages, message]),
        offlineFallback: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }

  Future<void> load(String roomId) async {
    final cachedThread = state.thread;
    emit(
      state.copyWith(
        status: cachedThread == null ? ChatStatus.loading : state.status,
        roomId: roomId,
        canRetrySend: false,
        offlineFallback: false,
        clearErrorMessage: true,
        clearSendErrorMessage: true,
      ),
    );
    try {
      final response = await repository.getThread(roomId);
      if (response.success && response.data != null) {
        final thread = response.data!;
        emit(
          state.copyWith(
            status: thread.messages.isEmpty
                ? ChatStatus.empty
                : ChatStatus.success,
            roomId: thread.roomId,
            thread: thread,
            offlineFallback: false,
            clearErrorMessage: true,
          ),
        );
        _subscribeRealtime(thread.roomId);
      } else {
        _emitLoadFailure(
          roomId: roomId,
          cachedThread: cachedThread,
          message: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.chatHistoryLoadFailed,
          ),
        );
      }
    } on ApiException catch (error) {
      _emitLoadFailure(
        roomId: roomId,
        cachedThread: cachedThread,
        message: userFacingErrorMessage(
          error,
          fallback: AppStrings.chatHistoryLoadFailed,
        ),
      );
    } catch (_) {
      _emitLoadFailure(
        roomId: roomId,
        cachedThread: cachedThread,
        message: AppStrings.chatHistoryLoadUnexpected,
      );
    }
  }

  /// Buyer mở tab Chat: lấy/tạo phòng hỗ trợ của chính mình (không cần roomId).
  Future<void> loadMyRoom() async {
    final cachedThread = state.thread;
    emit(
      state.copyWith(
        status: cachedThread == null ? ChatStatus.loading : state.status,
        canRetrySend: false,
        offlineFallback: false,
        clearErrorMessage: true,
        clearSendErrorMessage: true,
      ),
    );
    try {
      final response = await repository.getMyRoom();
      if (response.success && response.data != null) {
        final thread = response.data!;
        emit(
          state.copyWith(
            status: thread.messages.isEmpty
                ? ChatStatus.empty
                : ChatStatus.success,
            roomId: thread.roomId,
            thread: thread,
            offlineFallback: false,
            clearErrorMessage: true,
          ),
        );
        _subscribeRealtime(thread.roomId);
      } else {
        _emitLoadFailure(
          roomId: state.roomId ?? '',
          cachedThread: cachedThread,
          message: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.chatSupportRoomLoadFailed,
          ),
        );
      }
    } on ApiException catch (error) {
      _emitLoadFailure(
        roomId: state.roomId ?? '',
        cachedThread: cachedThread,
        message: userFacingErrorMessage(
          error,
          fallback: AppStrings.chatSupportRoomLoadFailed,
        ),
      );
    } catch (_) {
      _emitLoadFailure(
        roomId: state.roomId ?? '',
        cachedThread: cachedThread,
        message: AppStrings.chatSupportRoomLoadUnexpected,
      );
    }
  }

  Future<void> loadOrderRoom(String orderId) async {
    final cachedThread = state.thread;
    emit(
      state.copyWith(
        status: cachedThread == null ? ChatStatus.loading : state.status,
        canRetrySend: false,
        offlineFallback: false,
        clearErrorMessage: true,
        clearSendErrorMessage: true,
      ),
    );
    try {
      final response = await repository.getOrderRoom(orderId);
      if (response.success && response.data != null) {
        final thread = response.data!;
        emit(
          state.copyWith(
            status: thread.messages.isEmpty
                ? ChatStatus.empty
                : ChatStatus.success,
            roomId: thread.roomId,
            thread: thread,
            offlineFallback: false,
            clearErrorMessage: true,
          ),
        );
        _subscribeRealtime(thread.roomId);
      } else {
        _emitLoadFailure(
          roomId: state.roomId ?? '',
          cachedThread: cachedThread,
          message: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.complaintRoomCreateFailed,
          ),
        );
      }
    } on ApiException catch (error) {
      _emitLoadFailure(
        roomId: state.roomId ?? '',
        cachedThread: cachedThread,
        message: userFacingErrorMessage(
          error,
          fallback: AppStrings.complaintRoomCreateFailed,
        ),
      );
    } catch (_) {
      _emitLoadFailure(
        roomId: state.roomId ?? '',
        cachedThread: cachedThread,
        message: AppStrings.complaintRoomCreateUnexpected,
      );
    }
  }

  void _emitLoadFailure({
    required String roomId,
    required ChatThread? cachedThread,
    required String message,
  }) {
    if (cachedThread != null) {
      emit(
        state.copyWith(
          status: cachedThread.messages.isEmpty
              ? ChatStatus.empty
              : ChatStatus.success,
          roomId: roomId,
          thread: cachedThread,
          offlineFallback: true,
          errorMessage: AppStrings.offlineFallbackWithMessage(message),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ChatStatus.failure,
        roomId: roomId,
        offlineFallback: false,
        errorMessage: message,
      ),
    );
  }

  Future<void> sendMessage(String content, {bool sendAsStaff = false}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          sendErrorMessage: AppStrings.chatMessageRequired,
          canRetrySend: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        sending: true,
        canRetrySend: false,
        clearSendErrorMessage: true,
      ),
    );
    try {
      final roomId = await _resolveRoomIdForSend(sendAsStaff: sendAsStaff);
      if (roomId == null || roomId.isEmpty) {
        emit(
          state.copyWith(
            sending: false,
            canRetrySend: true,
            sendErrorMessage: AppStrings.chatRoomPrepareRetry,
          ),
        );
        return;
      }

      final response = await repository.sendMessage(
        roomId: roomId,
        content: trimmed,
        sendAsStaff: sendAsStaff,
      );
      if (response.success && response.data != null) {
        final sent = response.data!;
        final currentThread =
            state.thread ??
            ChatThread(roomId: roomId, isClosed: false, messages: const []);
        // The realtime echo can arrive before this REST response returns, so the
        // message may already be in the thread — dedupe by id to avoid a double.
        final alreadyPresent = currentThread.messages.any(
          (m) => m.id == sent.id,
        );
        final updatedThread = alreadyPresent
            ? currentThread
            : currentThread.copyWith(
                messages: [...currentThread.messages, sent],
              );
        emit(
          state.copyWith(
            status: ChatStatus.success,
            thread: updatedThread,
            sending: false,
            canRetrySend: false,
            clearSendErrorMessage: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            sending: false,
            canRetrySend: true,
            sendErrorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.chatSendFailed,
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          sending: false,
          canRetrySend: true,
          sendErrorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.chatSendFailed,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          canRetrySend: true,
          sendErrorMessage: AppStrings.chatSendUnexpected,
        ),
      );
    }
  }

  /// Bắt đầu một cuộc trò chuyện mới (dùng khi phòng hiện tại đã đóng —
  /// buyer bấm "Đoạn chat mới"). Tái sử dụng cùng cơ chế tạo phòng như màn
  /// danh sách chat; trả về roomId mới để mở, hoặc null nếu thất bại.
  Future<String?> createRoom() async {
    emit(state.copyWith(creating: true, clearSendErrorMessage: true));
    try {
      final response = await repository.createRoom();
      if (response.success && response.data != null) {
        emit(state.copyWith(creating: false));
        return response.data!.roomId;
      }
      emit(
        state.copyWith(
          creating: false,
          sendErrorMessage: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.newConversationCreateFailed,
          ),
        ),
      );
      return null;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          creating: false,
          sendErrorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.newConversationCreateFailed,
          ),
        ),
      );
      return null;
    } catch (_) {
      emit(
        state.copyWith(
          creating: false,
          sendErrorMessage: AppStrings.chatNewConversationCreateUnexpected,
        ),
      );
      return null;
    }
  }

  Future<String?> _resolveRoomIdForSend({required bool sendAsStaff}) async {
    final currentRoomId = state.roomId;
    if (currentRoomId != null && currentRoomId.isNotEmpty) {
      return currentRoomId;
    }
    if (sendAsStaff) {
      return null;
    }

    final response = await repository.getMyRoom();
    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.chatRoomPrepareFailed,
        type: ApiExceptionType.notFound,
      );
    }

    final thread = response.data!;
    emit(
      state.copyWith(
        status: thread.messages.isEmpty ? ChatStatus.empty : ChatStatus.success,
        roomId: thread.roomId,
        thread: thread,
        offlineFallback: false,
        clearErrorMessage: true,
      ),
    );
    _subscribeRealtime(thread.roomId);
    return thread.roomId;
  }
}
