import '../../../core/api/api_response.dart';
import 'admin_user.dart';

abstract class AdminUserRepository {
  Future<ApiResponse<List<AdminUser>>> getUsers();

  Future<ApiResponse<AdminUser>> approveUser(String id);

  /// Khóa tài khoản (status -> DISABLED). Người dùng bị khóa không đăng nhập được.
  Future<ApiResponse<AdminUser>> lockUser(String id);

  /// Mở khóa tài khoản (status -> ACTIVE).
  Future<ApiResponse<AdminUser>> unlockUser(String id);
}
