import '../domain/admin_dashboard.dart';

/// Maps the `data` object of GET /api/admin/dashboard to [AdminDashboard].
AdminDashboard adminDashboardFromJson(dynamic json) {
  final map = json as Map<String, dynamic>;
  final rawOrders = map['recentOrders'] as List<dynamic>? ?? const [];
  return AdminDashboard(
    pendingOrders: _toInt(map['pendingOrders']),
    monthlyRevenue: _toNum(map['monthlyRevenue']),
    newComplaints: _toInt(map['newComplaints']),
    activeUsers: _toInt(map['activeUsers']),
    lowStockProducts: _toInt(map['lowStockProducts']),
    recentOrders: rawOrders
        .whereType<Map<String, dynamic>>()
        .map(_recentOrderFromJson)
        .toList(),
  );
}

AdminRecentOrder _recentOrderFromJson(Map<String, dynamic> json) {
  return AdminRecentOrder(
    id: json['id']?.toString() ?? '',
    orderCode: json['orderCode']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    totalAmount: _toNum(json['totalAmount']),
  );
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
