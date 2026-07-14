import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_revenue.dart';
import '../domain/admin_revenue_repository.dart';
import 'admin_revenue_dto.dart';

class AdminRevenueRemoteRepository implements AdminRevenueRepository {
  final ApiClient apiClient;

  const AdminRevenueRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<RevenueReport>> getRevenue({
    required DateTime from,
    required DateTime to,
  }) {
    return apiClient.get<RevenueReport>(
      ApiEndpoints.adminRevenue,
      queryParameters: {'from': _formatDate(from), 'to': _formatDate(to)},
      fromJson: revenueReportFromJson,
    );
  }

  /// Formats a date as `yyyy-MM-dd` for the API query params.
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
