import '../../../core/api/api_response.dart';
import '../domain/warehouse.dart';
import '../domain/warehouse_repository.dart';

class WarehouseMockRepository implements WarehouseRepository {
  final List<Warehouse> _warehouses;

  WarehouseMockRepository({List<Warehouse>? warehouses})
    : _warehouses = warehouses ?? _defaultWarehouses;

  @override
  Future<ApiResponse<List<Warehouse>>> getWarehouses() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ApiResponse(
      success: true,
      message: 'OK',
      data: List.unmodifiable(_warehouses.where((item) => item.isActive)),
    );
  }
}

const _defaultWarehouses = [
  Warehouse(
    id: '550e8400-e29b-41d4-a716-446655460001',
    name: 'Kho Cần Thơ',
    address: '123 Trần Hưng Đạo, Ninh Kiều, Cần Thơ',
    phone: '0292000000',
    openingHours: '08:00-17:00',
    latitude: 10.0452,
    longitude: 105.7469,
    isActive: true,
  ),
  Warehouse(
    id: '550e8400-e29b-41d4-a716-446655460002',
    name: 'Kho Cà Mau',
    address: '45 Lý Thường Kiệt, Phường 6, Cà Mau',
    phone: '0290000000',
    openingHours: '07:30-16:30',
    latitude: 9.1768,
    longitude: 105.1524,
    isActive: true,
  ),
];
