import '../domain/admin_revenue.dart';

/// Maps the `data` object of GET /api/admin/revenue to [RevenueReport].
RevenueReport revenueReportFromJson(dynamic json) {
  final map = json as Map<String, dynamic>;
  final rawDaily = map['dailySeries'] as List<dynamic>? ?? const [];
  final rawTop = map['topProducts'] as List<dynamic>? ?? const [];
  return RevenueReport(
    from: _toDate(map['from']),
    to: _toDate(map['to']),
    totalRevenue: _toNum(map['totalRevenue']),
    dailySeries: rawDaily
        .whereType<Map<String, dynamic>>()
        .map(_dailyPointFromJson)
        .toList(),
    topProducts: rawTop
        .whereType<Map<String, dynamic>>()
        .map(_topProductFromJson)
        .toList(),
  );
}

DailyRevenuePoint _dailyPointFromJson(Map<String, dynamic> json) {
  return DailyRevenuePoint(
    date: _toDate(json['date']),
    revenue: _toNum(json['revenue']),
  );
}

TopProduct _topProductFromJson(Map<String, dynamic> json) {
  return TopProduct(
    productId: json['productId']?.toString() ?? '',
    productName: json['productName']?.toString() ?? '',
    quantitySold: _toInt(json['quantitySold']),
    revenue: _toNum(json['revenue']),
  );
}

DateTime _toDate(dynamic value) {
  final parsed = DateTime.tryParse('$value');
  // Normalise to a local date-only value so comparisons stay stable.
  if (parsed == null) return DateTime(1970);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
