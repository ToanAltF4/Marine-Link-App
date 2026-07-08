import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/notification_broadcast.dart';
import '../../domain/notification_repository.dart';

part 'broadcast_state.dart';

/// Admin/staff: compose broadcast notifications + view/delete the history.
class BroadcastCubit extends Cubit<BroadcastState> {
  final NotificationRepository notificationRepository;

  BroadcastCubit({required this.notificationRepository})
    : super(const BroadcastState());

  Future<void> loadBroadcasts() async {
    emit(state.copyWith(status: BroadcastStatus.loading, clearError: true));
    try {
      final response = await notificationRepository.getBroadcasts();
      if (response.success) {
        emit(
          state.copyWith(
            status: BroadcastStatus.ready,
            broadcasts: response.data ?? const <NotificationBroadcast>[],
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: BroadcastStatus.failure,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: 'Không tải được lịch sử thông báo.',
          ),
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: BroadcastStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Không tải được lịch sử thông báo.',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BroadcastStatus.failure,
          errorMessage: 'Đã xảy ra lỗi khi tải lịch sử thông báo.',
        ),
      );
    }
  }

  /// Returns true when the broadcast was created (so the UI can clear the form).
  Future<bool> createBroadcast({
    required String title,
    required String body,
  }) async {
    emit(state.copyWith(submitting: true, clearError: true, clearInfo: true));
    try {
      final response = await notificationRepository.createBroadcast(
        title: title.trim(),
        body: body.trim(),
      );
      if (response.success) {
        final created = response.data;
        final updated = <NotificationBroadcast>[
          ?created,
          ...state.broadcasts,
        ];
        emit(
          state.copyWith(
            status: BroadcastStatus.ready,
            broadcasts: created != null ? updated : state.broadcasts,
            submitting: false,
            infoMessage: 'Đã gửi thông báo đến các đại lý.',
            clearError: true,
          ),
        );
        return true;
      }
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: 'Không gửi được thông báo.',
          ),
        ),
      );
      return false;
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Không gửi được thông báo.',
          ),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: 'Đã xảy ra lỗi khi gửi thông báo.',
        ),
      );
      return false;
    }
  }

  Future<void> deleteBroadcast(String broadcastId) async {
    final previous = state.broadcasts;
    // Optimistic removal.
    emit(
      state.copyWith(
        broadcasts: previous
            .where((b) => b.broadcastId != broadcastId)
            .toList(),
        clearError: true,
        clearInfo: true,
      ),
    );
    try {
      final response = await notificationRepository.deleteBroadcast(broadcastId);
      if (response.success) {
        emit(state.copyWith(infoMessage: 'Đã xóa thông báo.'));
        return;
      }
      emit(
        state.copyWith(
          broadcasts: previous,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: 'Không xóa được thông báo.',
          ),
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          broadcasts: previous,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Không xóa được thông báo.',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          broadcasts: previous,
          errorMessage: 'Đã xảy ra lỗi khi xóa thông báo.',
        ),
      );
    }
  }
}
