part of 'warehouse_location_cubit.dart';

enum WarehouseLocationStatus {
  initial,
  checking,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  failure,
}

class WarehouseLocationState extends Equatable {
  final WarehouseLocationStatus status;
  final WarehouseUserLocation? location;
  final String? errorMessage;

  const WarehouseLocationState({
    this.status = WarehouseLocationStatus.initial,
    this.location,
    this.errorMessage,
  });

  WarehouseLocationState copyWith({
    WarehouseLocationStatus? status,
    WarehouseUserLocation? location,
    String? errorMessage,
  }) {
    return WarehouseLocationState(
      status: status ?? this.status,
      location: location ?? this.location,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, location, errorMessage];
}
