import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_location_service.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_repository.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_user_location.dart';
import 'package:marinelink/features/warehouse_map/presentation/cubit/warehouse_map_cubit.dart';
import 'package:marinelink/features/warehouse_map/presentation/screens/warehouse_map_screen.dart';

class _FakeRepo implements WarehouseRepository {
  final Future<ApiResponse<List<Warehouse>>> Function() responder;

  _FakeRepo(this.responder);

  @override
  Future<ApiResponse<List<Warehouse>>> getWarehouses() => responder();
}

void _registerRepo(WarehouseRepository repository) {
  sl.registerFactory<WarehouseMapCubit>(
    () => WarehouseMapCubit(repository: repository),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Future<bool> Function(Warehouse warehouse, WarehouseUserLocation? location)?
  mapLauncher,
  WarehouseLocationService? locationService,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: WarehouseMapScreen(
        mapLauncher: mapLauncher ?? (_, _) async => true,
        locationService: locationService ?? _FakeLocationService.denied(),
      ),
    ),
  );
}

void main() {
  setUp(() => sl.reset());
  tearDown(() => sl.reset());

  testWidgets('shows loading indicator while fetching warehouses', (
    tester,
  ) async {
    final completer = Completer<ApiResponse<List<Warehouse>>>();
    _registerRepo(_FakeRepo(() => completer.future));

    await _pumpScreen(tester);
    await tester.pump();

    expect(find.byKey(const Key('warehouseMapLoading')), findsOneWidget);

    completer.complete(
      const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warehouseMapLoading')), findsNothing);
  });

  testWidgets('renders warehouses and opens Google Maps action', (
    tester,
  ) async {
    var openedWarehouseId = '';
    _registerRepo(
      _FakeRepo(
        () async =>
            const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
      ),
    );

    await _pumpScreen(
      tester,
      mapLauncher: (warehouse, _) async {
        openedWarehouseId = warehouse.id;
        return true;
      },
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseMapList')), findsOneWidget);
    expect(find.byKey(const Key('warehouseSummaryCard')), findsOneWidget);
    expect(find.byKey(const Key('warehouseMapPreview')), findsOneWidget);
    expect(find.text('Kho Cần Thơ'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('warehouseOpenMapsButton_warehouse-001')),
    );
    await tester.pumpAndSettle();

    expect(openedWarehouseId, 'warehouse-001');
  });

  testWidgets('keeps warehouse list available when location is denied', (
    tester,
  ) async {
    final locationService = _FakeLocationService.denied();
    _registerRepo(
      _FakeRepo(
        () async =>
            const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
      ),
    );

    await _pumpScreen(tester, locationService: locationService);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseLocationDenied')), findsOneWidget);
    expect(find.byKey(const Key('warehouseMapList')), findsOneWidget);
    expect(
      find.byKey(const Key('warehouseOpenMapsButton_warehouse-001')),
      findsOneWidget,
    );

    locationService.requestResult = WarehouseLocationPermission.whileInUse;
    await tester.tap(find.byKey(const Key('warehouseLocationRequestButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseLocationGranted')), findsOneWidget);
  });

  testWidgets(
    'passes current location to map launcher when permission granted',
    (tester) async {
      WarehouseUserLocation? launcherLocation;
      _registerRepo(
        _FakeRepo(
          () async => const ApiResponse(
            success: true,
            message: 'OK',
            data: [_warehouse],
          ),
        ),
      );

      await _pumpScreen(
        tester,
        locationService: _FakeLocationService.granted(),
        mapLauncher: (_, location) async {
          launcherLocation = location;
          return true;
        },
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('warehouseLocationGranted')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('warehouseOpenMapsButton_warehouse-001')),
      );
      await tester.pumpAndSettle();

      expect(
        launcherLocation,
        const WarehouseUserLocation(latitude: 10.02, longitude: 105.78),
      );
    },
  );

  testWidgets('shows empty state when no active warehouse exists', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async => const ApiResponse(success: true, message: 'OK', data: []),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseMapEmpty')), findsOneWidget);
    expect(find.text('Chưa có kho hàng đang hoạt động.'), findsOneWidget);
  });

  testWidgets('shows error and retries successfully', (tester) async {
    var calls = 0;
    _registerRepo(
      _FakeRepo(() async {
        calls++;
        if (calls == 1) {
          return const ApiResponse(success: false, message: 'Mất kết nối');
        }
        return const ApiResponse(
          success: true,
          message: 'OK',
          data: [_warehouse],
        );
      }),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseMapError')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);

    await tester.tap(find.byKey(const Key('warehouseMapRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehouseMapError')), findsNothing);
    expect(find.byKey(const Key('warehouseMapList')), findsOneWidget);
  });
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

class _FakeLocationService implements WarehouseLocationService {
  bool serviceEnabled;
  WarehouseLocationPermission permission;
  WarehouseLocationPermission requestResult;
  WarehouseUserLocation location;
  bool openedAppSettings = false;
  bool openedLocationSettings = false;

  _FakeLocationService({
    required this.serviceEnabled,
    required this.permission,
    required this.requestResult,
    required this.location,
  });

  factory _FakeLocationService.denied() {
    return _FakeLocationService(
      serviceEnabled: true,
      permission: WarehouseLocationPermission.denied,
      requestResult: WarehouseLocationPermission.denied,
      location: const WarehouseUserLocation(latitude: 10.02, longitude: 105.78),
    );
  }

  factory _FakeLocationService.granted() {
    return _FakeLocationService(
      serviceEnabled: true,
      permission: WarehouseLocationPermission.whileInUse,
      requestResult: WarehouseLocationPermission.whileInUse,
      location: const WarehouseUserLocation(latitude: 10.02, longitude: 105.78),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<WarehouseLocationPermission> checkPermission() async => permission;

  @override
  Future<WarehouseLocationPermission> requestPermission() async {
    permission = requestResult;
    return requestResult;
  }

  @override
  Future<WarehouseUserLocation> getCurrentLocation() async => location;

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings = true;
    return true;
  }
}
