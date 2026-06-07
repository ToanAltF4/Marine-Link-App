import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_repository.dart';
import 'package:marinelink/features/warehouse_map/presentation/cubit/warehouse_map_cubit.dart';

class _FakeRepo implements WarehouseRepository {
  final Future<ApiResponse<List<Warehouse>>> Function() responder;

  _FakeRepo(this.responder);

  @override
  Future<ApiResponse<List<Warehouse>>> getWarehouses() => responder();
}

void main() {
  blocTest<WarehouseMapCubit, WarehouseMapState>(
    'emits [loading, success] when warehouses are returned',
    build: () => WarehouseMapCubit(
      repository: _FakeRepo(
        () async =>
            const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<WarehouseMapState>().having(
        (state) => state.status,
        'status',
        WarehouseMapStatus.loading,
      ),
      isA<WarehouseMapState>()
          .having((state) => state.status, 'status', WarehouseMapStatus.success)
          .having((state) => state.warehouses, 'warehouses', [_warehouse]),
    ],
  );

  blocTest<WarehouseMapCubit, WarehouseMapState>(
    'emits [loading, empty] when repository returns no warehouses',
    build: () => WarehouseMapCubit(
      repository: _FakeRepo(
        () async => const ApiResponse(success: true, message: 'OK', data: []),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<WarehouseMapState>().having(
        (state) => state.status,
        'status',
        WarehouseMapStatus.loading,
      ),
      isA<WarehouseMapState>().having(
        (state) => state.status,
        'status',
        WarehouseMapStatus.empty,
      ),
    ],
  );

  blocTest<WarehouseMapCubit, WarehouseMapState>(
    'emits [loading, failure] when repository reports failure',
    build: () => WarehouseMapCubit(
      repository: _FakeRepo(
        () async => const ApiResponse(success: false, message: 'Mất kết nối'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<WarehouseMapState>().having(
        (state) => state.status,
        'status',
        WarehouseMapStatus.loading,
      ),
      isA<WarehouseMapState>()
          .having((state) => state.status, 'status', WarehouseMapStatus.failure)
          .having((state) => state.errorMessage, 'errorMessage', 'Mất kết nối'),
    ],
  );
}

const _warehouse = Warehouse(
  id: 'warehouse-001',
  name: 'Kho Cần Thơ',
  address: '123 Trần Hưng Đạo, Cần Thơ',
  phone: '0292000000',
  openingHours: '08:00-17:00',
  latitude: 10.0452,
  longitude: 105.7469,
  isActive: true,
);
