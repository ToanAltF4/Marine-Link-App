import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_user_location.dart';
import 'package:marinelink/features/warehouse_map/presentation/screens/warehouse_map_screen.dart';

const _warehouse = Warehouse(
  id: 'wh-can-tho',
  name: 'Kho Cần Thơ',
  address: '123 Trần Hưng Đạo, Ninh Kiều, Cần Thơ',
  phone: '0292 123 456',
  openingHours: '08:00 - 17:00',
  latitude: 10.033333,
  longitude: 105.783333,
  isActive: true,
);

void main() {
  group('buildWarehouseDirectionsUri', () {
    test('luôn chỉ đường tới đúng toạ độ cửa hàng (không phải tìm kiếm)', () {
      final uri = buildWarehouseDirectionsUri(_warehouse, null);

      // Phải là endpoint CHỈ ĐƯỜNG, không phải /maps/search/ (search hay bị
      // Google "hút" sang địa điểm gần nhất => sai điểm đến).
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '10.033333,105.783333');
      expect(uri.queryParameters['api'], '1');
      // Không có vị trí người dùng -> bỏ origin, Google tự lấy vị trí hiện tại.
      expect(uri.queryParameters.containsKey('origin'), isFalse);
      // Không được dùng chuỗi địa chỉ làm điểm đến.
      expect(uri.toString(), isNot(contains('Trần')));
      expect(uri.queryParameters.containsKey('query'), isFalse);
    });

    test('kèm origin khi đã biết vị trí người dùng', () {
      final uri = buildWarehouseDirectionsUri(
        _warehouse,
        const WarehouseUserLocation(latitude: 10.762622, longitude: 106.660172),
      );

      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['origin'], '10.762622,106.660172');
      expect(uri.queryParameters['destination'], '10.033333,105.783333');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('mỗi cửa hàng cho ra đúng toạ độ của chính nó', () {
      const other = Warehouse(
        id: 'wh-ca-mau',
        name: 'Kho Cà Mau',
        address: '45 Lý Thường Kiệt, Phường 6, Cà Mau',
        phone: '0290 123 456',
        openingHours: '08:00 - 17:00',
        latitude: 9.176870,
        longitude: 105.150307,
        isActive: true,
      );

      expect(
        buildWarehouseDirectionsUri(other, null).queryParameters['destination'],
        '9.17687,105.150307',
      );
      expect(
        buildWarehouseDirectionsUri(
          _warehouse,
          null,
        ).queryParameters['destination'],
        '10.033333,105.783333',
      );
    });
  });
}
