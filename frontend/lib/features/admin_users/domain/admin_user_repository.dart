import '../../../core/api/api_response.dart';
import 'admin_user.dart';

abstract class AdminUserRepository {
  Future<ApiResponse<List<AdminUser>>> getUsers();

  Future<ApiResponse<AdminUser>> approveUser(String id);

  /// Khóa tài khoản (status -> DISABLED). Người dùng bị khóa không đăng nhập được.
  Future<ApiResponse<AdminUser>> lockUser(String id);

  /// Mở khóa tài khoản (status -> ACTIVE).
  Future<ApiResponse<AdminUser>> unlockUser(String id);

  /// Admin tạo tài khoản mới (mặc định STAFF). Tài khoản được kích hoạt luôn
  /// (status = ACTIVE), không cần chờ duyệt.
  Future<ApiResponse<AdminUser>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleCode = 'STAFF',
  });
}
