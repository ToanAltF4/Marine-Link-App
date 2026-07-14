import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/warehouse_map/data/warehouse_dto.dart';

void main() {
  test('maps warehouse contract payload to domain model', () {
    final warehouse = warehouseFromJson({
      'id': 'warehouse-001',
      'name': 'Kho Cần Thơ',
      'address': '123 Trần Hưng Đạo, Cần Thơ',
      'phone': '0292000000',
      'openingHours': '08:00-17:00',
      'latitude': '10.0452000',
      'longitude': 105.7469,
      'isActive': true,
    });

    expect(warehouse.id, 'warehouse-001');
    expect(warehouse.name, 'Kho Cần Thơ');
    expect(warehouse.phone, '0292000000');
    expect(warehouse.openingHours, '08:00-17:00');
    expect(warehouse.latitude, 10.0452);
    expect(warehouse.longitude, 105.7469);
    expect(warehouse.isActive, isTrue);
  });

  test('maps list payload and tolerates snake_case fields', () {
    final warehouses = warehousesFromJson([
      {
        'public_id': 'warehouse-002',
        'name': 'Kho Cà Mau',
        'address': '45 Lý Thường Kiệt, Cà Mau',
        'opening_hours': '07:30-16:30',
        'latitude': 9.1768,
        'longitude': '105.1524',
        'is_active': 'true',
      },
    ]);

    expect(warehouses, hasLength(1));
    expect(warehouses.single.id, 'warehouse-002');
    expect(warehouses.single.openingHours, '07:30-16:30');
    expect(warehouses.single.isActive, isTrue);
  });
}
