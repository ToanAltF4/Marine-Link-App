import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;

  ChatCubit({required this.repository}) : super(const ChatState());

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
      } else {
        _emitLoadFailure(
          roomId: roomId,
          cachedThread: cachedThread,
          message:
              response.message ??
              'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c l\u1ecbch s\u1eed chat.',
        );
      }
    } on ApiException catch (error) {
      _emitLoadFailure(
        roomId: roomId,
        cachedThread: cachedThread,
        message: error.message,
      );
    } catch (_) {
      _emitLoadFailure(
        roomId: roomId,
        cachedThread: cachedThread,
        message:
            '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi t\u1ea3i l\u1ecbch s\u1eed chat.',
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
          errorMessage:
              '$message \u0110ang hi\u1ec3n th\u1ecb d\u1eef li\u1ec7u g\u1ea7n nh\u1ea5t.',
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
          sendErrorMessage:
              'Vui l\u00f2ng nh\u1eadp n\u1ed9i dung tin nh\u1eafn.',
          canRetrySend: false,
        ),
      );
      return;
    }
    final roomId = state.roomId;
    if (roomId == null || roomId.isEmpty) {
      emit(
        state.copyWith(
          sendErrorMessage:
              'Ch\u01b0a c\u00f3 ph\u00f2ng chat \u0111\u1ec3 g\u1eedi tin.',
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
      final response = await repository.sendMessage(
        roomId: roomId,
        content: trimmed,
        sendAsStaff: sendAsStaff,
      );
      if (response.success && response.data != null) {
        final currentThread =
            state.thread ??
            ChatThread(roomId: roomId, isClosed: false, messages: const []);
        final updatedThread = currentThread.copyWith(
          messages: [...currentThread.messages, response.data!],
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
            sendErrorMessage:
                response.message ??
                'Kh\u00f4ng g\u1eedi \u0111\u01b0\u1ee3c tin nh\u1eafn.',
          ),
        );
      }
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          sending: false,
          canRetrySend: true,
          sendErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          canRetrySend: true,
          sendErrorMessage:
              '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi g\u1eedi tin nh\u1eafn.',
        ),
      );
    }
  }
}
