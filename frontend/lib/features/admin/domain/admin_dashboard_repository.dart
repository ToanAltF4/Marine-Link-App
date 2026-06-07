import '../../../core/api/api_response.dart';
import 'admin_dashboard.dart';

/// Admin dashboard repository interface.
/// Mock implementation: AdminDashboardMockRepository (data/)
/// Remote implementation: AdminDashboardRemoteRepository (data/)
abstract class AdminDashboardRepository {
  Future<ApiResponse<AdminDashboard>> getDashboard();
}
