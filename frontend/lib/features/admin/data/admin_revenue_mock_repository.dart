import '../../../core/api/api_response.dart';
import '../domain/admin_revenue.dart';
import '../domain/admin_revenue_repository.dart';

/// In-memory revenue analytics for mock-first development and tests.
///
/// Generates a believable daily series for the requested range plus a small
/// list of best-selling products, so the screen looks realistic without a
/// backend.
class AdminRevenueMockRepository implements AdminRevenueRepository {
  const AdminRevenueMockRepository();

  @override
  Future<ApiResponse<RevenueReport>> getRevenue({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);

    final daily = <DailyRevenuePoint>[];
    num total = 0;
    for (
      var day = fromDay;
      !day.isAfter(toDay);
      day = day.add(const Duration(days: 1))
    ) {
      // Deterministic pseudo figures: weekdays sell more, weekends dip; a few
      // days have no sales so the empty-day rendering is exercised.
      final base = 1500000 + (day.day % 7) * 850000;
      final weekendDip = (day.weekday >= 6) ? 600000 : 0;
      final gap = (day.day % 11 == 0) ? 0 : 1;
      final revenue = (base - weekendDip) * gap;
      daily.add(DailyRevenuePoint(date: day, revenue: revenue));
      total += revenue;
    }

    const topProducts = [
      TopProduct(
        productId: 'prod-squid',
        productName: 'Mực khô loại 1',
        quantitySold: 128,
        revenue: 25600000,
      ),
      TopProduct(
        productId: 'prod-shrimp',
        productName: 'Tôm khô tuyển chọn',
        quantitySold: 96,
        revenue: 19200000,
      ),
      TopProduct(
        productId: 'prod-fish-sauce',
        productName: 'Nước mắm cá cơm 40 độ đạm',
        quantitySold: 74,
        revenue: 11100000,
      ),
      TopProduct(
        productId: 'prod-dried-fish',
        productName: 'Cá chỉ vàng khô',
        quantitySold: 51,
        revenue: 7650000,
      ),
      TopProduct(
        productId: 'prod-seaweed',
        productName: 'Rong biển sấy',
        quantitySold: 33,
        revenue: 3300000,
      ),
    ];

    return ApiResponse(
      success: true,
      message: 'OK',
      data: RevenueReport(
        from: fromDay,
        to: toDay,
        totalRevenue: total,
        dailySeries: daily,
        topProducts: topProducts,
      ),
    );
  }
}
