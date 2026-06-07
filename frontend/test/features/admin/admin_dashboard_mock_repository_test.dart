import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin/data/admin_dashboard_mock_repository.dart';

void main() {
  test('AdminDashboardMockRepository returns a successful overview', () async {
    final repo = AdminDashboardMockRepository();

    final response = await repo.getDashboard();

    expect(response.success, isTrue);
    final data = response.data;
    expect(data, isNotNull);
    expect(data!.pendingOrders, greaterThan(0));
    expect(data.monthlyRevenue, greaterThan(0));
    expect(data.lowStockProducts, greaterThan(0));
    expect(data.activeUsers, greaterThan(0));
    expect(data.recentOrders, isNotEmpty);
  });
}
