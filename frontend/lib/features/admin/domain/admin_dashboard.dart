import 'package:equatable/equatable.dart';

/// One row in the admin dashboard "recent orders" list.
/// Mirrors `recentOrders[]` in GET /api/admin/dashboard.
class AdminRecentOrder extends Equatable {
  final String id; // public_id
  final String orderCode;
  final String status;
  final num totalAmount;

  const AdminRecentOrder({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [id, orderCode, status, totalAmount];
}

/// Admin dashboard overview aggregate.
/// Mirrors `data` of GET /api/admin/dashboard (see
/// docs/MarineLink_API_Documentation.md).
class AdminDashboard extends Equatable {
  final int pendingOrders;
  final num monthlyRevenue;
  final int newComplaints;
  final int activeUsers;
  final int lowStockProducts;
  final List<AdminRecentOrder> recentOrders;

  const AdminDashboard({
    required this.pendingOrders,
    required this.monthlyRevenue,
    required this.newComplaints,
    required this.activeUsers,
    required this.lowStockProducts,
    this.recentOrders = const [],
  });

  @override
  List<Object?> get props => [
    pendingOrders,
    monthlyRevenue,
    newComplaints,
    activeUsers,
    lowStockProducts,
    recentOrders,
  ];
}
