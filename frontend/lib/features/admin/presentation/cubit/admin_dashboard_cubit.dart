import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/admin_dashboard.dart';
import '../../domain/admin_dashboard_repository.dart';

part 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminDashboardRepository repository;

  AdminDashboardCubit({required this.repository})
    : super(const AdminDashboardState());

  Future<void> load() async {
    emit(state.copyWith(status: AdminDashboardStatus.loading));
    try {
      final response = await repository.getDashboard();
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: AdminDashboardStatus.success,
            dashboard: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdminDashboardStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: 'Không tải được dữ liệu tổng quan.',
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminDashboardStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Đã xảy ra lỗi khi tải tổng quan hệ thống.',
          ),
        ),
      );
    }
  }
}
