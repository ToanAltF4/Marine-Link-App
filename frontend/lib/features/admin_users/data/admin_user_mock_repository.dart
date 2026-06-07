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
        message: 'Không tìm thấy tài khoản cần duyệt.',
      );
    }

    final updated = _users[index].copyWith(status: AdminUserStatus.active);
    _users[index] = updated;
    return ApiResponse(success: true, message: 'OK', data: updated);
  }
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
  ),
  AdminUser(
    id: 'user-dealer-pending',
    fullName: 'Đại lý Chờ Duyệt',
    email: 'pending@marinelink.demo',
    phone: '0911111222',
    role: AdminUserRole.user,
    status: AdminUserStatus.pendingApproval,
  ),
  AdminUser(
    id: 'user-dealer-disabled',
    fullName: 'Đại lý Tạm Khóa',
    email: 'disabled@marinelink.demo',
    phone: '0922222333',
    role: AdminUserRole.user,
    status: AdminUserStatus.disabled,
  ),
];
