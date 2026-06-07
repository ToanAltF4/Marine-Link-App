part of 'admin_user_cubit.dart';

enum AdminUserStatusView { initial, loading, success, empty, failure }

class AdminUserState extends Equatable {
  final AdminUserStatusView status;
  final List<AdminUser> users;
  final AdminUserRole? selectedRole;
  final AdminUserStatus? selectedUserStatus;
  final String? approvingUserId;
  final String? errorMessage;

  const AdminUserState({
    this.status = AdminUserStatusView.initial,
    this.users = const [],
    this.selectedRole,
    this.selectedUserStatus,
    this.approvingUserId,
    this.errorMessage,
  });

  List<AdminUser> get visibleUsers {
    return users.where((user) {
      final roleMatches = selectedRole == null || user.role == selectedRole;
      final statusMatches =
          selectedUserStatus == null || user.status == selectedUserStatus;
      return roleMatches && statusMatches;
    }).toList();
  }

  AdminUserState copyWith({
    AdminUserStatusView? status,
    List<AdminUser>? users,
    AdminUserRole? selectedRole,
    bool clearSelectedRole = false,
    AdminUserStatus? selectedUserStatus,
    bool clearSelectedUserStatus = false,
    String? approvingUserId,
    bool clearApprovingUserId = false,
    String? errorMessage,
  }) {
    return AdminUserState(
      status: status ?? this.status,
      users: users ?? this.users,
      selectedRole: clearSelectedRole
          ? null
          : selectedRole ?? this.selectedRole,
      selectedUserStatus: clearSelectedUserStatus
          ? null
          : selectedUserStatus ?? this.selectedUserStatus,
      approvingUserId: clearApprovingUserId
          ? null
          : approvingUserId ?? this.approvingUserId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    selectedRole,
    selectedUserStatus,
    approvingUserId,
    errorMessage,
  ];
}
