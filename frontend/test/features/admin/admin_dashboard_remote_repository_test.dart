import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/data/admin_dashboard_remote_repository.dart';
import 'package:marinelink/features/admin/domain/admin_dashboard.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('AdminDashboardRemoteRepository calls dashboard endpoint', () async {
    final apiClient = _MockApiClient();
    const dashboard = AdminDashboard(
      pendingOrders: 2,
      monthlyRevenue: 1200000,
      newComplaints: 1,
      activeUsers: 12,
      lowStockProducts: 3,
    );

    when(
      () => apiClient.get<AdminDashboard>(
        ApiEndpoints.adminDashboard,
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(success: true, data: dashboard),
    );

    final repository = AdminDashboardRemoteRepository(apiClient: apiClient);

    final response = await repository.getDashboard();

    expect(response.data, dashboard);
    verify(
      () => apiClient.get<AdminDashboard>(
        ApiEndpoints.adminDashboard,
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });
}
