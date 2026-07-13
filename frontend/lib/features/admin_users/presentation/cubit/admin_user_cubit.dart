import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

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
              fallback: AppStrings.adminUsersLoadFailed,
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
            fallback: AppStrings.adminUsersLoadUnexpected,
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

  /// Admin tạo tài khoản mới (mặc định STAFF).
  ///
  /// Trả về `true` khi tạo thành công; khi thất bại trả về `false` và đặt
  /// [AdminUserState.errorMessage] để form hiển thị SnackBar lỗi.
  ///
  /// Lỗi tạo tài khoản KHÔNG chuyển màn danh sách sang trạng thái failure:
  /// form đang mở phía trên, người dùng chỉ cần sửa lại thông tin nhập.
  Future<bool> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleCode = 'STAFF',
  }) async {
    emit(state.copyWith(creatingUser: true));
    try {
      final response = await repository.createUser(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        roleCode: roleCode,
      );
      if (response.success && response.data != null) {
        final created = response.data!;
        final users = [
          created,
          for (final user in state.users)
            if (user.id != created.id) user,
        ];
        emit(
          state.copyWith(
            status: AdminUserStatusView.success,
            users: users,
            creatingUser: false,
          ),
        );
        return true;
      }

      emit(
        state.copyWith(
          creatingUser: false,
          errorMessage: userFacingResponseMessage(
            response.message,
            fallback: AppStrings.adminCreateUserFailed,
          ),
        ),
      );
      return false;
    } catch (error) {
      emit(
        state.copyWith(
          creatingUser: false,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.adminCreateUserUnexpected,
          ),
        ),
      );
      return false;
    }
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
              fallback: AppStrings.adminUserApproveFailed,
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
            fallback: AppStrings.adminUserApproveUnexpected,
          ),
          clearApprovingUserId: true,
        ),
      );
    }
  }
}
