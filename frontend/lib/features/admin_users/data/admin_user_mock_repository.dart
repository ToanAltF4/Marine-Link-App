import 'package:marinelink/core/constants/app_strings.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_user.dart';
import '../domain/admin_user_repository.dart';

class AdminUserMockRepository implements AdminUserRepository {
  final List<AdminUser> _users;

  AdminUserMockRepository({List<AdminUser>? initialUsers})
    : _users = List.of(initialUsers ?? _sampleUsers);

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ApiResponse(success: true, message: 'OK', data: List.of(_users));
  }

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      return const ApiResponse(
        success: false,
        message: AppStrings.adminUserApproveFailed,
      );
    }

    final updated = _users[index].copyWith(status: AdminUserStatus.active);
    _users[index] = updated;
    return ApiResponse(success: true, message: 'OK', data: updated);
  }

  @override
  Future<ApiResponse<AdminUser>> lockUser(String id) =>
      _setStatus(id, AdminUserStatus.disabled, AppStrings.adminUserLockFailed);

  @override
  Future<ApiResponse<AdminUser>> unlockUser(String id) =>
      _setStatus(id, AdminUserStatus.active, AppStrings.adminUserUnlockFailed);

  @override
  Future<ApiResponse<AdminUser>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleCode = 'STAFF',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final normalizedEmail = email.trim().toLowerCase();
    final exists = _users.any(
      (user) => user.email.trim().toLowerCase() == normalizedEmail,
    );
    if (exists) {
      return const ApiResponse(
        success: false,
        message: AppStrings.adminCreateUserEmailExists,
      );
    }

    final created = AdminUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: _roleFromCode(roleCode),
      // Tài khoản do admin tạo được kích hoạt luôn.
      status: AdminUserStatus.active,
    );
    _users.add(created);
    return ApiResponse(success: true, message: 'OK', data: created);
  }

  Future<ApiResponse<AdminUser>> _setStatus(
    String id,
    AdminUserStatus status,
    String failureMessage,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      return ApiResponse(success: false, message: failureMessage);
    }

    final updated = _users[index].copyWith(status: status);
    _users[index] = updated;
    return ApiResponse(success: true, message: 'OK', data: updated);
  }
}

AdminUserRole _roleFromCode(String roleCode) {
  return switch (roleCode.trim().toUpperCase()) {
    'ADMIN' => AdminUserRole.admin,
    'USER' => AdminUserRole.user,
    _ => AdminUserRole.staff,
  };
}

const _sampleUsers = [
  AdminUser(
    id: 'user-admin-001',
    fullName: 'MarineLink Admin',
    email: 'admin@marinelink.demo',
    phone: '0900000000',
    role: AdminUserRole.admin,
    status: AdminUserStatus.active,
  ),
  AdminUser(
    id: 'user-staff-001',
    fullName: 'Nhân viên Demo',
    email: 'staff@marinelink.demo',
    phone: '0900000001',
    role: AdminUserRole.staff,
    status: AdminUserStatus.active,
  ),
  AdminUser(
    id: 'user-dealer-001',
    fullName: 'Đại lý Nguyễn Văn A',
    email: 'daily-a@marinelink.demo',
    phone: '0912345678',
    role: AdminUserRole.user,
    status: AdminUserStatus.active,
    taxCode: '0301234567',
    storeName: 'Cửa hàng Ngư cụ Nguyễn Văn A',
    businessAddress: '25 Nguyễn Tất Thành, Quận 4, TP. Hồ Chí Minh',
  ),
  AdminUser(
    id: 'user-dealer-pending',
    fullName: 'Đại lý Chờ Duyệt',
    email: 'pending@marinelink.demo',
    phone: '0911111222',
    role: AdminUserRole.user,
    status: AdminUserStatus.pendingApproval,
    taxCode: '0409876543',
    storeName: 'Cửa hàng Hải sản Long Hải',
    businessAddress: '148 Trần Phú, TP. Vũng Tàu, Bà Rịa - Vũng Tàu',
  ),
  AdminUser(
    id: 'user-dealer-disabled',
    fullName: 'Đại lý Tạm Khóa',
    email: 'disabled@marinelink.demo',
    phone: '0922222333',
    role: AdminUserRole.user,
    status: AdminUserStatus.disabled,
    taxCode: '0312223334',
    storeName: 'Cửa hàng Ngư nghiệp Biển Đông',
    businessAddress: '90 Hùng Vương, TP. Nha Trang, Khánh Hòa',
  ),
];
