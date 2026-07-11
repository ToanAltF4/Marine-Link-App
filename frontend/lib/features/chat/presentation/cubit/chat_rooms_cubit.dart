import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'chat_rooms_state.dart';

/// Buyer chat history: the list of the user's conversations + "New chat".
class ChatRoomsCubit extends Cubit<ChatRoomsState> {
  final ChatRepository repository;

  ChatRoomsCubit({required this.repository}) : super(const ChatRoomsState());

  /// Load the conversation list. Pass [silent] to refresh in place (e.g. when
  /// returning from a thread) without flashing the loading state.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ChatRoomsStatus.loading, clearError: true));
    }
    try {
      final response = await repository.getMyRooms();
      if (response.success && response.data != null) {
        final rooms = response.data!;
        emit(
          state.copyWith(
            status: rooms.isEmpty
                ? ChatRoomsStatus.empty
                : ChatRoomsStatus.success,
            rooms: rooms,
          ),
        );
      } else {
        _fail(
          userFacingResponseMessage(
            response.message,
            fallback: AppStrings.chatHistoryLoadFailed,
          ),
        );
      }
    } on ApiException catch (error) {
      _fail(
        userFacingErrorMessage(
          error,
          fallback: AppStrings.chatHistoryLoadFailed,
        ),
      );
    } catch (_) {
      _fail(AppStrings.chatHistoryLoadUnexpected);
    }
  }

  /// Create a new conversation; returns the new roomId (or null on failure).
  Future<String?> createRoom() async {
    emit(state.copyWith(creating: true, clearError: true));
    try {
      final response = await repository.createRoom();
      if (response.success && response.data != null) {
        emit(state.copyWith(creating: false));
        return response.data!.roomId;
      }
      emit(
        state.copyWith(
          creating: false,
          errorMessage: userFacingResponseMessage(
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
          errorMessage: userFacingErrorMessage(
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
          errorMessage: AppStrings.chatNewConversationCreateUnexpected,
        ),
      );
      return null;
    }
  }

  void _fail(String message) {
    emit(
      state.copyWith(status: ChatRoomsStatus.failure, errorMessage: message),
    );
  }
}
