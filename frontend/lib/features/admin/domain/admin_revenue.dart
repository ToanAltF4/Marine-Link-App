import 'package:equatable/equatable.dart';

/// Revenue for a single day in the report series.
/// Mirrors one entry of `dailySeries[]` in GET /api/admin/revenue.
class DailyRevenuePoint extends Equatable {
  final DateTime date;
  final num revenue;

  const DailyRevenuePoint({required this.date, required this.revenue});

  @override
  List<Object?> get props => [date, revenue];
}

/// One best-selling product in the report.
/// Mirrors one entry of `topProducts[]` in GET /api/admin/revenue.
class TopProduct extends Equatable {
  final String productId;
  final String productName;
  final int quantitySold;
  final num revenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  @override
  List<Object?> get props => [productId, productName, quantitySold, revenue];
}

/// Revenue analytics aggregate for a resolved date range.
/// Mirrors `data` of GET /api/admin/revenue (see
/// docs/MarineLink_API_Documentation.md).
class RevenueReport extends Equatable {
  final DateTime from;
  final DateTime to;
  final num totalRevenue;
  final List<DailyRevenuePoint> dailySeries;
  final List<TopProduct> topProducts;

  const RevenueReport({
    required this.from,
    required this.to,
    required this.totalRevenue,
    this.dailySeries = const [],
    this.topProducts = const [],
  });

  /// The largest single-day revenue in the series (0 when empty).
  /// Handy for scaling the daily bar chart.
  num get maxDailyRevenue {
    num max = 0;
    for (final point in dailySeries) {
      if (point.revenue > max) max = point.revenue;
    }
    return max;
  }

  bool get hasSales => totalRevenue > 0;

  @override
  List<Object?> get props => [from, to, totalRevenue, dailySeries, topProducts];
}
