import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_dashboard.dart';
import '../domain/admin_dashboard_repository.dart';
import 'admin_dashboard_dto.dart';

class AdminDashboardRemoteRepository implements AdminDashboardRepository {
  final ApiClient apiClient;

  const AdminDashboardRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<AdminDashboard>> getDashboard() {
    return apiClient.get<AdminDashboard>(
      ApiEndpoints.adminDashboard,
      fromJson: adminDashboardFromJson,
    );
  }
}
