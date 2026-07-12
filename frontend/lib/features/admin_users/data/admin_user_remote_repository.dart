import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_user.dart';
import '../domain/admin_user_repository.dart';
import 'admin_user_dto.dart';

class AdminUserRemoteRepository implements AdminUserRepository {
  final ApiClient apiClient;

  const AdminUserRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() {
    return apiClient.get<List<AdminUser>>(
      ApiEndpoints.adminUsers,
      fromJson: adminUsersFromJson,
    );
  }

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) {
    return apiClient.put<AdminUser>(
      ApiEndpoints.adminUserDetail(id),
      data: const {'status': 'ACTIVE'},
      fromJson: adminUserFromJson,
    );
  }

  @override
  Future<ApiResponse<AdminUser>> lockUser(String id) {
    return apiClient.put<AdminUser>(
      ApiEndpoints.adminUserDetail(id),
      data: const {'status': 'DISABLED'},
      fromJson: adminUserFromJson,
    );
  }

  @override
  Future<ApiResponse<AdminUser>> unlockUser(String id) {
    return apiClient.put<AdminUser>(
      ApiEndpoints.adminUserDetail(id),
      data: const {'status': 'ACTIVE'},
      fromJson: adminUserFromJson,
    );
  }
}
