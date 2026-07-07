import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'chat_rooms_state.dart';

/// Buyer chat history: the list of the user's conversations + "New chat".
class ChatRoomsCubit extends Cubit<ChatRoomsState> {
  final ChatRepository repository;

  ChatRoomsCubit({required this.repository}) : super(const ChatRoomsState());

  Future<void> load() async {
    emit(state.copyWith(status: ChatRoomsStatus.loading, clearError: true));
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
            fallback: 'Không tải được lịch sử chat.',
          ),
        );
      }
    } on ApiException catch (error) {
      _fail(
        userFacingErrorMessage(
          error,
          fallback: 'Không tải được lịch sử chat.',
        ),
      );
    } catch (_) {
      _fail('Đã xảy ra lỗi khi tải lịch sử chat.');
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
            fallback: 'Không tạo được cuộc trò chuyện mới.',
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
            fallback: 'Không tạo được cuộc trò chuyện mới.',
          ),
        ),
      );
      return null;
    } catch (_) {
      emit(
        state.copyWith(
          creating: false,
          errorMessage: 'Đã xảy ra lỗi khi tạo cuộc trò chuyện mới.',
        ),
      );
      return null;
    }
  }

  void _fail(String message) {
    emit(state.copyWith(status: ChatRoomsStatus.failure, errorMessage: message));
  }
}
