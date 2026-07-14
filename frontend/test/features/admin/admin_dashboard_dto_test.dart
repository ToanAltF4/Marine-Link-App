import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin/data/admin_dashboard_dto.dart';

void main() {
  group('adminDashboardFromJson', () {
    test('maps the full contract payload', () {
      final json = {
        'pendingOrders': 5,
        'monthlyRevenue': 125000000,
        'newComplaints': 2,
        'activeUsers': 18,
        'lowStockProducts': 3,
        'recentOrders': [
          {
            'id': '550e8400-e29b-41d4-a716-446655440009',
            'orderCode': 'ML-20260528-0001',
            'status': 'PENDING',
            'totalAmount': 4200000,
          },
        ],
      };

      final result = adminDashboardFromJson(json);

      expect(result.pendingOrders, 5);
      expect(result.monthlyRevenue, 125000000);
      expect(result.newComplaints, 2);
      expect(result.activeUsers, 18);
      expect(result.lowStockProducts, 3);
      expect(result.recentOrders, hasLength(1));
      expect(result.recentOrders.first.orderCode, 'ML-20260528-0001');
      expect(result.recentOrders.first.status, 'PENDING');
      expect(result.recentOrders.first.totalAmount, 4200000);
    });

    test('defaults missing fields and empty recentOrders safely', () {
      final result = adminDashboardFromJson(<String, dynamic>{});

      expect(result.pendingOrders, 0);
      expect(result.monthlyRevenue, 0);
      expect(result.newComplaints, 0);
      expect(result.activeUsers, 0);
      expect(result.lowStockProducts, 0);
      expect(result.recentOrders, isEmpty);
    });

    test('parses numeric fields delivered as strings', () {
      final json = {
        'pendingOrders': '7',
        'monthlyRevenue': '99000000',
        'newComplaints': '1',
        'activeUsers': '4',
        'lowStockProducts': '2',
      };

      final result = adminDashboardFromJson(json);

      expect(result.pendingOrders, 7);
      expect(result.monthlyRevenue, 99000000);
      expect(result.activeUsers, 4);
    });
  });
}
