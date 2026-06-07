import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/orders/data/order_mock_repository.dart';
import 'package:marinelink/features/orders/domain/order.dart';

void main() {
  final repo = OrderMockRepository();

  test('returns every demo order when no status filter is applied', () async {
    final response = await repo.getOrders();

    expect(response.success, isTrue);
    final statuses = response.data!.map((o) => o.status).toSet();
    // All five lifecycle states are represented for staff/admin management.
    expect(statuses, containsAll(OrderStatus.values));
  });

  test('filters by COMPLETED status', () async {
    final response = await repo.getOrders(status: 'COMPLETED');

    expect(response.success, isTrue);
    expect(response.data, isNotEmpty);
    expect(
      response.data!.every((o) => o.status == OrderStatus.completed),
      isTrue,
    );
  });

  test('filters by CANCELLED status', () async {
    final response = await repo.getOrders(status: 'CANCELLED');

    expect(response.success, isTrue);
    expect(response.data, isNotEmpty);
    expect(
      response.data!.every((o) => o.status == OrderStatus.cancelled),
      isTrue,
    );
  });
}
