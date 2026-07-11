import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin/data/admin_revenue_remote_repository.dart';
import 'package:marinelink/features/admin/domain/admin_revenue.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('calls the revenue endpoint with yyyy-MM-dd from/to query params',
      () async {
    final apiClient = _MockApiClient();
    final report = RevenueReport(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 30),
      totalRevenue: 1000000,
    );

    when(
      () => apiClient.get<RevenueReport>(
        ApiEndpoints.adminRevenue,
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => ApiResponse(success: true, data: report));

    final repository = AdminRevenueRemoteRepository(apiClient: apiClient);

    final response = await repository.getRevenue(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 30),
    );

    expect(response.data, report);
    final captured = verify(
      () => apiClient.get<RevenueReport>(
        ApiEndpoints.adminRevenue,
        queryParameters: captureAny(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(captured['from'], '2026-06-01');
    expect(captured['to'], '2026-06-30');
  });
}
