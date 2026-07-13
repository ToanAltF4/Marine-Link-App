import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse.dart';
import 'package:marinelink/features/warehouse_map/domain/warehouse_user_location.dart';
import 'package:marinelink/features/warehouse_map/presentation/widgets/warehouse_osm_map.dart';

import 'fake_tile_provider.dart';

Warehouse _warehouse(String id, double latitude, double longitude) {
  return Warehouse(
    id: id,
    name: 'Kho $id',
    address: 'Địa chỉ $id',
    phone: null,
    openingHours: null,
    latitude: latitude,
    longitude: longitude,
    isActive: true,
  );
}

/// 5 kho — nhiều hơn 4 để chứng minh bản đồ KHÔNG cắt danh sách (`take(4)`).
final _warehouses = [
  _warehouse('wh-1', 10.0452, 105.7469),
  _warehouse('wh-2', 9.176870, 105.150307),
  _warehouse('wh-3', 10.2899, 105.7500),
  _warehouse('wh-4', 9.6031, 105.9739),
  _warehouse('wh-5', 10.7626, 106.6601),
];

Future<void> _pumpMap(
  WidgetTester tester, {
  required List<Warehouse> warehouses,
  Warehouse? selected,
  WarehouseUserLocation? userLocation,
  ValueChanged<Warehouse>? onSelected,
  MapController? controller,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(600, 600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WarehouseOsmMap(
          warehouses: warehouses,
          selectedWarehouse: selected,
          userLocation: userLocation,
          mapController: controller,
          tileProvider: FakeTileProvider(),
          height: 420,
          onWarehouseSelected: onSelected ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Marker> _markers(WidgetTester tester) {
  return tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
}

void main() {
  testWidgets('dựng bản đồ OSM thật với tile layer của OpenStreetMap', (
    tester,
  ) async {
    await _pumpMap(tester, warehouses: _warehouses);

    expect(find.byKey(const Key('warehouseOsmMap')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(
      tileLayer.urlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    // `userAgentPackageName` được TileLayer nhét vào header User-Agent.
    expect(
      tileLayer.tileProvider.headers['User-Agent'],
      contains('com.marinelink.marinelink'),
    );

    // Ghi công OpenStreetMap là BẮT BUỘC theo Tile Usage Policy.
    // SimpleAttributionWidget dựng 'flutter_map | © ' + nguồn.
    expect(find.byKey(const Key('warehouseOsmAttribution')), findsOneWidget);
    expect(find.text('flutter_map | © '), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('mỗi kho có đúng một marker tại toạ độ của chính nó', (
    tester,
  ) async {
    await _pumpMap(tester, warehouses: _warehouses);

    final markers = _markers(tester);
    expect(markers, hasLength(_warehouses.length));

    for (final warehouse in _warehouses) {
      final marker = markers.singleWhere(
        (m) => m.key == Key('warehouseMarker_${warehouse.id}'),
      );
      expect(marker.point, LatLng(warehouse.latitude, warehouse.longitude));
      expect(
        find.byKey(Key('warehouseMarker_${warehouse.id}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('chạm marker trả về đúng đối tượng Warehouse của marker đó', (
    tester,
  ) async {
    Warehouse? selected;
    await _pumpMap(
      tester,
      warehouses: _warehouses,
      onSelected: (warehouse) => selected = warehouse,
    );

    await tester.tap(find.byKey(const Key('warehouseMarker_wh-4')));
    await tester.pumpAndSettle();

    expect(selected, same(_warehouses[3]));
    expect(selected!.latitude, 9.6031);
    expect(selected!.longitude, 105.9739);
  });

  testWidgets('marker của kho đang chọn được làm nổi bật (to hơn)', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      warehouses: _warehouses,
      selected: _warehouses[1],
    );

    final markers = _markers(tester);
    final selectedMarker = markers.singleWhere(
      (m) => m.key == const Key('warehouseMarker_wh-2'),
    );
    final otherMarker = markers.singleWhere(
      (m) => m.key == const Key('warehouseMarker_wh-1'),
    );

    expect(selectedMarker.width, greaterThan(otherMarker.width));
    expect(selectedMarker.height, greaterThan(otherMarker.height));
  });

  testWidgets('chọn kho khác thì bản đồ move() tới đúng toạ độ kho đó', (
    tester,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);

    await _pumpMap(tester, warehouses: _warehouses, controller: controller);

    // Rebuild với kho đang chọn -> bản đồ phải bay tới toạ độ của kho đó.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WarehouseOsmMap(
            warehouses: _warehouses,
            selectedWarehouse: _warehouses[4],
            mapController: controller,
            tileProvider: FakeTileProvider(),
            height: 420,
            onWarehouseSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.camera.center.latitude, closeTo(10.7626, 0.0001));
    expect(controller.camera.center.longitude, closeTo(106.6601, 0.0001));
    expect(controller.camera.zoom, WarehouseOsmMap.selectedZoom);
  });

  testWidgets('hiện marker vị trí người dùng khi đã biết vị trí', (
    tester,
  ) async {
    await _pumpMap(tester, warehouses: _warehouses);
    expect(find.byKey(const Key('warehouseUserLocationMarker')), findsNothing);

    await _pumpMap(
      tester,
      warehouses: _warehouses,
      userLocation: const WarehouseUserLocation(
        latitude: 10.0452,
        longitude: 105.7469,
      ),
    );

    final userMarker = _markers(tester).singleWhere(
      (m) => m.key == const Key('warehouseUserLocationMarker'),
    );
    expect(userMarker.point, const LatLng(10.0452, 105.7469));
    expect(
      find.byKey(const Key('warehouseUserLocationMarker')),
      findsOneWidget,
    );
  });
}
