import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/app/di/service_locator.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/shared/widgets/buyer_bottom_nav.dart';
import 'package:marinelink/shared/widgets/role_bottom_nav.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_location_service.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_repository.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_user_location.dart';
import 'package:marinelink/features/warehouse_map/presentation/cubit/warehouse_map_cubit.dart';
import 'package:marinelink/features/warehouse_map/presentation/screens/warehouse_map_screen.dart';
import 'package:marinelink/features/warehouse_map/presentation/widgets/warehouse_card.dart';
import 'package:marinelink/features/warehouse_map/presentation/widgets/warehouse_osm_map.dart';

import 'fake_tile_provider.dart';

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
  MapController? mapController,
  // Bản đồ OSM thật cao hơn khung minh hoạ cũ nên viewport test cần cao hơn để
  // thẻ kho + nút "Chỉ đường" nằm trọn trong màn.
  Size size = const Size(430, 1400),
  bool adminMode = false,
  bool staffMode = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: WarehouseMapScreen(
        adminMode: adminMode,
        staffMode: staffMode,
        mapLauncher: mapLauncher ?? (_, _) async => true,
        locationService: locationService ?? _FakeLocationService.denied(),
        mapController: mapController,
        // Không bao giờ gọi mạng để tải tile trong test.
        tileProvider: FakeTileProvider(),
      ),
    ),
  );
}

bool _isCardSelected(WidgetTester tester, String id) {
  return tester
      .widget<WarehouseCard>(
        find.byWidgetPredicate(
          (widget) => widget is WarehouseCard && widget.warehouse.id == id,
        ),
      )
      .selected;
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
    expect(find.byKey(const Key('warehouseOsmMap')), findsOneWidget);
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

  testWidgets('bản đồ có marker cho TẤT CẢ kho (không chỉ 4 kho đầu)', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _warehouses),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    final markers = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers;
    expect(_warehouses.length, greaterThan(4));
    expect(markers, hasLength(_warehouses.length));

    for (final warehouse in _warehouses) {
      final marker = markers.singleWhere(
        (m) => m.key == Key('warehouseMarker_${warehouse.id}'),
      );
      // Toạ độ marker = toạ độ của chính đối tượng Warehouse.
      expect(marker.point.latitude, warehouse.latitude);
      expect(marker.point.longitude, warehouse.longitude);
    }
  });

  testWidgets('chạm thẻ kho -> chọn kho đó và bản đồ move() tới toạ độ kho', (
    tester,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _warehouses),
      ),
    );

    await _pumpScreen(
      tester,
      mapController: controller,
      size: const Size(430, 2600),
    );
    await tester.pumpAndSettle();

    expect(_isCardSelected(tester, 'wh-5'), isFalse);

    await tester.tap(find.byKey(const Key('warehouseCardSelect_wh-5')));
    await tester.pumpAndSettle();

    // Thẻ được làm nổi bật...
    expect(_isCardSelected(tester, 'wh-5'), isTrue);
    // ...và bản đồ đã bay tới đúng toạ độ của kho đó.
    final selected = _warehouses[4];
    expect(controller.camera.center.latitude, closeTo(selected.latitude, 1e-4));
    expect(
      controller.camera.center.longitude,
      closeTo(selected.longitude, 1e-4),
    );
    expect(controller.camera.zoom, WarehouseOsmMap.selectedZoom);

    // Marker của kho đang chọn to hơn các marker còn lại.
    final markers = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers;
    final selectedMarker = markers.singleWhere(
      (m) => m.key == const Key('warehouseMarker_wh-5'),
    );
    final otherMarker = markers.singleWhere(
      (m) => m.key == const Key('warehouseMarker_wh-1'),
    );
    expect(selectedMarker.width, greaterThan(otherMarker.width));
  });

  testWidgets('chạm marker -> chọn kho và làm nổi bật đúng thẻ của kho đó', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _warehouses),
      ),
    );

    await _pumpScreen(tester, size: const Size(430, 2600));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('warehouseMarker_wh-2')));
    await tester.pumpAndSettle();

    expect(_isCardSelected(tester, 'wh-2'), isTrue);
    expect(_isCardSelected(tester, 'wh-1'), isFalse);
  });

  testWidgets('nút "Chỉ đường" dùng đúng toạ độ của kho đang được chọn', (
    tester,
  ) async {
    Warehouse? launched;
    _registerRepo(
      _FakeRepo(
        () async =>
            ApiResponse(success: true, message: 'OK', data: _warehouses),
      ),
    );

    await _pumpScreen(
      tester,
      size: const Size(430, 2600),
      locationService: _FakeLocationService.granted(),
      mapLauncher: (warehouse, _) async {
        launched = warehouse;
        return true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('warehouseCardSelect_wh-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('warehouseOpenMapsButton_wh-3')));
    await tester.pumpAndSettle();

    final selected = _warehouses[2];
    // Thẻ / marker / nút "Chỉ đường" dùng CHUNG một đối tượng Warehouse.
    expect(launched, same(selected));

    final uri = buildWarehouseDirectionsUri(
      launched!,
      const WarehouseUserLocation(latitude: 10.02, longitude: 105.78),
    );
    expect(uri.path, '/maps/dir/');
    expect(
      uri.queryParameters['destination'],
      '${selected.latitude},${selected.longitude}',
    );
    expect(uri.queryParameters['origin'], '10.02,105.78');
  });

  testWidgets('admin xem kho: dùng thanh điều hướng của admin', (tester) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
      ),
    );

    await _pumpScreen(tester, adminMode: true);
    await tester.pumpAndSettle();

    expect(find.byType(AdminBottomNav), findsOneWidget);
    expect(find.byType(BuyerBottomNav), findsNothing);
  });

  testWidgets('đại lý xem kho: dùng thanh điều hướng của đại lý', (
    tester,
  ) async {
    _registerRepo(
      _FakeRepo(
        () async =>
            const ApiResponse(success: true, message: 'OK', data: [_warehouse]),
      ),
    );

    await _pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(BuyerBottomNav), findsOneWidget);
    expect(find.byType(AdminBottomNav), findsNothing);
  });
}

Warehouse _makeWarehouse(String id, double latitude, double longitude) {
  return Warehouse(
    id: id,
    name: 'Kho $id',
    address: 'Địa chỉ $id',
    phone: '0292000000',
    openingHours: '08:00-17:00',
    latitude: latitude,
    longitude: longitude,
    isActive: true,
  );


}

/// 5 kho — nhiều hơn 4 để chắc chắn bản đồ không cắt bớt danh sách.
final _warehouses = [
  _makeWarehouse('wh-1', 10.0452, 105.7469),
  _makeWarehouse('wh-2', 9.176870, 105.150307),
  _makeWarehouse('wh-3', 10.2899, 105.7500),
  _makeWarehouse('wh-4', 9.6031, 105.9739),
  _makeWarehouse('wh-5', 10.7626, 106.6601),
];

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
