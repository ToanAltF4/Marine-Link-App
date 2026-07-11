import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin/data/admin_revenue_dto.dart';

void main() {
  test('revenueReportFromJson maps range, daily series and top products', () {
    final json = {
      'from': '2026-06-01',
      'to': '2026-06-03',
      'totalRevenue': 1750000,
      'dailySeries': [
        {'date': '2026-06-01', 'revenue': 0},
        {'date': '2026-06-02', 'revenue': 1500000},
        {'date': '2026-06-03', 'revenue': 250000},
      ],
      'topProducts': [
        {
          'productId': '550e8400-e29b-41d4-a716-446655440777',
          'productName': 'Mực khô loại 1',
          'quantitySold': 42,
          'revenue': 8400000,
        },
      ],
    };

    final report = revenueReportFromJson(json);

    expect(report.from, DateTime(2026, 6, 1));
    expect(report.to, DateTime(2026, 6, 3));
    expect(report.totalRevenue, 1750000);
    expect(report.dailySeries, hasLength(3));
    expect(report.dailySeries[1].date, DateTime(2026, 6, 2));
    expect(report.dailySeries[1].revenue, 1500000);
    expect(report.maxDailyRevenue, 1500000);
    expect(report.hasSales, isTrue);
    expect(report.topProducts, hasLength(1));
    expect(report.topProducts.first.productName, 'Mực khô loại 1');
    expect(report.topProducts.first.quantitySold, 42);
    expect(report.topProducts.first.revenue, 8400000);
  });

  test('revenueReportFromJson tolerates missing lists and string numbers', () {
    final report = revenueReportFromJson({
      'from': '2026-06-01',
      'to': '2026-06-30',
      'totalRevenue': '0',
    });

    expect(report.totalRevenue, 0);
    expect(report.dailySeries, isEmpty);
    expect(report.topProducts, isEmpty);
    expect(report.hasSales, isFalse);
  });
}
