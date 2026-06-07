import '../../../core/api/api_response.dart';
import 'admin_user.dart';

abstract class AdminUserRepository {
  Future<ApiResponse<List<AdminUser>>> getUsers();

  Future<ApiResponse<AdminUser>> approveUser(String id);
}
