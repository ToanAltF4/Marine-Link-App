import '../../../core/api/api_response.dart';
import 'admin_revenue.dart';

/// Admin revenue repository interface.
/// Mock implementation: AdminRevenueMockRepository (data/)
/// Remote implementation: AdminRevenueRemoteRepository (data/)
abstract class AdminRevenueRepository {
  /// Fetches the revenue report for the inclusive day range [from, to].
  Future<ApiResponse<RevenueReport>> getRevenue({
    required DateTime from,
    required DateTime to,
  });
}
