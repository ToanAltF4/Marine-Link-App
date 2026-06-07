import '../../../core/api/api_response.dart';
import '../domain/admin_dashboard.dart';
import '../domain/admin_dashboard_repository.dart';

/// In-memory admin dashboard data for mock-first development and tests.
class AdminDashboardMockRepository implements AdminDashboardRepository {
  @override
  Future<ApiResponse<AdminDashboard>> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AdminDashboard(
        pendingOrders: 18,
        monthlyRevenue: 42850000,
        newComplaints: 2,
        activeUsers: 12,
        lowStockProducts: 5,
        recentOrders: [
          AdminRecentOrder(
            id: 'order-2901',
            orderCode: 'ML-2901',
            status: 'PENDING',
            totalAmount: 12400000,
          ),
          AdminRecentOrder(
            id: 'order-2895',
            orderCode: 'ML-2895',
            status: 'DELIVERED',
            totalAmount: 8250000,
          ),
          AdminRecentOrder(
            id: 'order-2890',
            orderCode: 'ML-2890',
            status: 'PROCESSING',
            totalAmount: 5100000,
          ),
        ],
      ),
    );
  }
}
