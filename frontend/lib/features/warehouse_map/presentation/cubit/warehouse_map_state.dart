part of 'warehouse_map_cubit.dart';

enum WarehouseMapStatus { initial, loading, success, empty, failure }

class WarehouseMapState extends Equatable {
  final WarehouseMapStatus status;
  final List<Warehouse> warehouses;
  final String? errorMessage;

  const WarehouseMapState({
    this.status = WarehouseMapStatus.initial,
    this.warehouses = const [],
    this.errorMessage,
  });

  WarehouseMapState copyWith({
    WarehouseMapStatus? status,
    List<Warehouse>? warehouses,
    String? errorMessage,
  }) {
    return WarehouseMapState(
      status: status ?? this.status,
      warehouses: warehouses ?? this.warehouses,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, warehouses, errorMessage];
}
