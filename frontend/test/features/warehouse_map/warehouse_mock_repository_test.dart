import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/warehouse_map/data/warehouse_mock_repository.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';

void main() {
  test('returns only active warehouses from in-memory data', () async {
    final repository = WarehouseMockRepository(
      warehouses: const [
        Warehouse(
          id: 'active',
          name: 'Kho hoạt động',
          address: 'Cần Thơ',
          phone: null,
          openingHours: null,
          latitude: 10,
          longitude: 105,
          isActive: true,
        ),
        Warehouse(
          id: 'disabled',
          name: 'Kho tạm đóng',
          address: 'Cà Mau',
          phone: null,
          openingHours: null,
          latitude: 9,
          longitude: 105,
          isActive: false,
        ),
      ],
    );

    final response = await repository.getWarehouses();

    expect(response.success, isTrue);
    expect(response.data, hasLength(1));
    expect(response.data!.single.id, 'active');
  });
}
