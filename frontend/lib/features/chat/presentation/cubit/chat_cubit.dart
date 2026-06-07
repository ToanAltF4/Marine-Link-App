import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;

  ChatCubit({required this.repository}) : super(const ChatState());

  Future<void> load(String roomId) async {
    emit(
      state.copyWith(
        status: ChatStatus.loading,
        roomId: roomId,
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
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage:
                response.message ??
                'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c l\u1ecbch s\u1eed chat.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage:
              '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi t\u1ea3i l\u1ecbch s\u1eed chat.',
        ),
      );
    }
  }

  Future<void> sendMessage(String content, {bool sendAsStaff = false}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          sendErrorMessage:
              'Vui l\u00f2ng nh\u1eadp n\u1ed9i dung tin nh\u1eafn.',
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
        ),
      );
      return;
    }

    emit(state.copyWith(sending: true, clearSendErrorMessage: true));
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
            clearSendErrorMessage: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            sending: false,
            sendErrorMessage:
                response.message ??
                'Kh\u00f4ng g\u1eedi \u0111\u01b0\u1ee3c tin nh\u1eafn.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          sendErrorMessage:
              '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi g\u1eedi tin nh\u1eafn.',
        ),
      );
    }
  }
}
