import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
              errorMessage:
                  response.message ??
                  'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c danh s\u00e1ch chat.',
            ),
          );
        }
      }
    } catch (_) {
      if (showLoading) {
        emit(
          state.copyWith(
            status: StaffChatStatus.failure,
            errorMessage:
                '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi t\u1ea3i danh s\u00e1ch chat.',
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
                ? 'Ph\u00f2ng chat \u0111\u00e3 chuy\u1ec3n sang \u0111\u00e3 x\u1eed l\u00fd.'
                : 'Ph\u00f2ng chat \u0111\u00e3 \u0111\u01b0\u1ee3c m\u1edf l\u1ea1i.',
          ),
        );
        await load();
      } else {
        emit(
          state.copyWith(
            clearUpdatingRoomId: true,
            actionErrorMessage:
                response.message ??
                'Kh\u00f4ng c\u1eadp nh\u1eadt \u0111\u01b0\u1ee3c tr\u1ea1ng th\u00e1i chat.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          clearUpdatingRoomId: true,
          actionErrorMessage:
              '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi c\u1eadp nh\u1eadt chat.',
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
          actionErrorMessage:
              'Vui l\u00f2ng nh\u1eadp ti\u00eau \u0111\u1ec1 v\u00e0 m\u00f4 t\u1ea3 khi\u1ebfu n\u1ea1i.',
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
            actionMessage:
                'Khi\u1ebfu n\u1ea1i \u0111\u00e3 \u0111\u01b0\u1ee3c t\u1ea1o t\u1eeb chat.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            clearUpdatingRoomId: true,
            actionErrorMessage:
                response.message ??
                'Kh\u00f4ng t\u1ea1o \u0111\u01b0\u1ee3c khi\u1ebfu n\u1ea1i.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          clearUpdatingRoomId: true,
          actionErrorMessage:
              '\u0110\u00e3 x\u1ea3y ra l\u1ed7i khi t\u1ea1o khi\u1ebfu n\u1ea1i.',
        ),
      );
    }
  }
}
