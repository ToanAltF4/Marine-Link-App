import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/chat.dart';
import '../../domain/chat_repository.dart';

part 'staff_chat_state.dart';

class StaffChatCubit extends Cubit<StaffChatState> {
  final ChatRepository repository;

  StaffChatCubit({required this.repository}) : super(const StaffChatState());

  Future<void> load() => _load(showLoading: true);

  Future<void> refresh() => _load(showLoading: false);

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) {
      emit(
        state.copyWith(
          status: StaffChatStatus.loading,
          clearErrorMessage: true,
          clearActionMessage: true,
        ),
      );
    }
    try {
      final response = await repository.getStaffRooms(
        filter: state.filter,
        query: state.query,
      );
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: response.data!.isEmpty
                ? StaffChatStatus.empty
                : StaffChatStatus.success,
            rooms: response.data!,
            clearErrorMessage: true,
          ),
        );
      } else {
        if (showLoading) {
          emit(
            state.copyWith(
              status: StaffChatStatus.failure,
              errorMessage: userFacingResponseMessage(
                response.message,
                fallback: AppStrings.staffChatLoadFailed,
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (showLoading) {
        emit(
          state.copyWith(
            status: StaffChatStatus.failure,
            errorMessage: userFacingErrorMessage(
              error,
              fallback: AppStrings.staffChatLoadUnexpected,
            ),
          ),
        );
      }
    }
  }

  Future<void> setFilter(StaffChatRoomFilter filter) async {
    emit(state.copyWith(filter: filter));
    await load();
  }

  Future<void> setQuery(String query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> setRoomClosed(String roomId, bool isClosed) async {
    emit(state.copyWith(updatingRoomId: roomId, clearActionMessage: true));
    try {
      final response = await repository.setRoomClosed(
        roomId: roomId,
        isClosed: isClosed,
      );
      if (response.success) {
        final rooms = state.rooms.map((room) {
          if (room.roomId != roomId) return room;
          return room.copyWith(isClosed: response.data?.isClosed ?? isClosed);
        }).toList();
        emit(
          state.copyWith(
            status: rooms.isEmpty
                ? StaffChatStatus.empty
                : StaffChatStatus.success,
            rooms: rooms,
            clearUpdatingRoomId: true,
            actionMessage: isClosed
                ? AppStrings.chatRoomStatusUpdatedClosed
                : AppStrings.chatRoomStatusUpdatedOpen,
          ),
        );
        await load();
      } else {
        emit(
          state.copyWith(
            clearUpdatingRoomId: true,
            actionErrorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.chatRoomStatusUpdateFailed,
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          clearUpdatingRoomId: true,
          actionErrorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.chatRoomStatusUpdateUnexpected,
          ),
        ),
      );
    }
  }

  Future<void> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty || trimmedDescription.isEmpty) {
      emit(
        state.copyWith(
          actionErrorMessage: AppStrings.complaintTitleDescriptionRequired,
        ),
      );
      return;
    }
    emit(state.copyWith(updatingRoomId: roomId, clearActionMessage: true));
    try {
      final response = await repository.createComplaint(
        roomId: roomId,
        title: trimmedTitle,
        description: trimmedDescription,
        messageId: messageId,
      );
      if (response.success) {
        emit(
          state.copyWith(
            clearUpdatingRoomId: true,
            actionMessage: AppStrings.complaintCreatedFromChat,
          ),
        );
      } else {
        emit(
          state.copyWith(
            clearUpdatingRoomId: true,
            actionErrorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.complaintCreateFailed,
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          clearUpdatingRoomId: true,
          actionErrorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.complaintCreateUnexpected,
          ),
        ),
      );
    }
  }
}
