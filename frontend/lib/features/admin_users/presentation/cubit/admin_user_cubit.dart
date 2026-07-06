import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../domain/admin_user.dart';
import '../../domain/admin_user_repository.dart';

part 'admin_user_state.dart';

class AdminUserCubit extends Cubit<AdminUserState> {
  final AdminUserRepository repository;

  AdminUserCubit({required this.repository}) : super(const AdminUserState());

  Future<void> load() async {
    emit(state.copyWith(status: AdminUserStatusView.loading));
    try {
      final response = await repository.getUsers();
      if (response.success && response.data != null) {
        final users = response.data!;
        emit(
          state.copyWith(
            status: users.isEmpty
                ? AdminUserStatusView.empty
                : AdminUserStatusView.success,
            users: users,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdminUserStatusView.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: 'Không tải được danh sách tài khoản.',
            ),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminUserStatusView.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Đã xảy ra lỗi khi tải danh sách tài khoản.',
          ),
        ),
      );
    }
  }

  void setRoleFilter(AdminUserRole? role) {
    emit(state.copyWith(selectedRole: role, clearSelectedRole: role == null));
  }

  void setStatusFilter(AdminUserStatus? status) {
    emit(
      state.copyWith(
        selectedUserStatus: status,
        clearSelectedUserStatus: status == null,
      ),
    );
  }

  Future<void> approveUser(String id) async {
    emit(state.copyWith(approvingUserId: id));
    try {
      final response = await repository.approveUser(id);
      if (response.success && response.data != null) {
        final updated = response.data!;
        final users = [
          for (final user in state.users)
            if (user.id == updated.id) updated else user,
        ];
        emit(
          state.copyWith(
            status: users.isEmpty
                ? AdminUserStatusView.empty
                : AdminUserStatusView.success,
            users: users,
            clearApprovingUserId: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AdminUserStatusView.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: 'Không duyệt được tài khoản.',
            ),
            clearApprovingUserId: true,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminUserStatusView.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: 'Đã xảy ra lỗi khi duyệt tài khoản.',
          ),
          clearApprovingUserId: true,
        ),
      );
    }
  }
}
