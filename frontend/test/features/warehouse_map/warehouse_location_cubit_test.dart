import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_location_service.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_user_location.dart';
import 'package:marinelink/features/warehouse_map/presentation/cubit/warehouse_location_cubit.dart';

void main() {
  blocTest<WarehouseLocationCubit, WarehouseLocationState>(
    'emits [checking, granted] when permission is already granted',
    build: () =>
        WarehouseLocationCubit(service: _FakeLocationService.granted()),
    act: (cubit) => cubit.loadStatus(),
    expect: () => [
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.checking,
      ),
      isA<WarehouseLocationState>()
          .having(
            (state) => state.status,
            'status',
            WarehouseLocationStatus.granted,
          )
          .having((state) => state.location, 'location', _location),
    ],
  );

  blocTest<WarehouseLocationCubit, WarehouseLocationState>(
    'emits [checking, denied] when permission is not granted',
    build: () => WarehouseLocationCubit(service: _FakeLocationService.denied()),
    act: (cubit) => cubit.loadStatus(),
    expect: () => [
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.checking,
      ),
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.denied,
      ),
    ],
  );

  blocTest<WarehouseLocationCubit, WarehouseLocationState>(
    'requests permission and then emits granted',
    build: () => WarehouseLocationCubit(
      service: _FakeLocationService.denied(
        requestResult: WarehouseLocationPermission.whileInUse,
      ),
    ),
    act: (cubit) => cubit.requestCurrentLocation(),
    expect: () => [
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.checking,
      ),
      isA<WarehouseLocationState>()
          .having(
            (state) => state.status,
            'status',
            WarehouseLocationStatus.granted,
          )
          .having((state) => state.location, 'location', _location),
    ],
  );

  blocTest<WarehouseLocationCubit, WarehouseLocationState>(
    'emits serviceDisabled when device location service is off',
    build: () => WarehouseLocationCubit(
      service: _FakeLocationService(
        serviceEnabled: false,
        permission: WarehouseLocationPermission.whileInUse,
        requestResult: WarehouseLocationPermission.whileInUse,
      ),
    ),
    act: (cubit) => cubit.loadStatus(),
    expect: () => [
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.checking,
      ),
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.serviceDisabled,
      ),
    ],
  );

  blocTest<WarehouseLocationCubit, WarehouseLocationState>(
    'emits deniedForever when permission is permanently denied',
    build: () => WarehouseLocationCubit(
      service: _FakeLocationService(
        serviceEnabled: true,
        permission: WarehouseLocationPermission.deniedForever,
        requestResult: WarehouseLocationPermission.deniedForever,
      ),
    ),
    act: (cubit) => cubit.loadStatus(),
    expect: () => [
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.checking,
      ),
      isA<WarehouseLocationState>().having(
        (state) => state.status,
        'status',
        WarehouseLocationStatus.deniedForever,
      ),
    ],
  );
}

const _location = WarehouseUserLocation(latitude: 10.02, longitude: 105.78);

class _FakeLocationService implements WarehouseLocationService {
  final bool serviceEnabled;
  final WarehouseLocationPermission permission;
  final WarehouseLocationPermission requestResult;

  _FakeLocationService({
    required this.serviceEnabled,
    required this.permission,
    required this.requestResult,
  });

  factory _FakeLocationService.granted() {
    return _FakeLocationService(
      serviceEnabled: true,
      permission: WarehouseLocationPermission.whileInUse,
      requestResult: WarehouseLocationPermission.whileInUse,
    );
  }

  factory _FakeLocationService.denied({
    WarehouseLocationPermission requestResult =
        WarehouseLocationPermission.denied,
  }) {
    return _FakeLocationService(
      serviceEnabled: true,
      permission: WarehouseLocationPermission.denied,
      requestResult: requestResult,
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<WarehouseLocationPermission> checkPermission() async => permission;

  @override
  Future<WarehouseLocationPermission> requestPermission() async =>
      requestResult;

  @override
  Future<WarehouseUserLocation> getCurrentLocation() async => _location;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
