import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:marinelink/core/constants/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/warehouse.dart';
import '../../domain/warehouse_user_location.dart';
import 'warehouse_common_widgets.dart';

/// Bản đồ OpenStreetMap **thật** cho màn kho hàng.
///
/// Mỗi kho trong [warehouses] có đúng **một** marker đặt tại
/// `LatLng(warehouse.latitude, warehouse.longitude)` — toạ độ của chính đối
/// tượng [Warehouse] là **nguồn chính xác duy nhất**, dùng chung cho marker,
/// thẻ kho và nút "Chỉ đường".
///
/// Chạm vào marker sẽ gọi [onWarehouseSelected] với **đúng** đối tượng
/// [Warehouse] đó. Khi [selectedWarehouse] đổi, bản đồ tự `move()` tới toạ độ
/// của kho đang chọn (zoom [selectedZoom]) và marker đó được làm nổi bật.
class WarehouseOsmMap extends StatefulWidget {
  /// Toàn bộ kho cần hiển thị (KHÔNG cắt bớt).
  final List<Warehouse> warehouses;

  /// Kho đang được chọn (marker sẽ to hơn + đổi màu).
  final Warehouse? selectedWarehouse;

  /// Vị trí hiện tại của người dùng (nếu đã có quyền).
  final WarehouseUserLocation? userLocation;

  /// Gọi khi người dùng chạm vào một marker kho.
  final ValueChanged<Warehouse> onWarehouseSelected;

  /// Cho phép màn hình bên ngoài giữ/điều khiển camera. Nếu null thì widget tự
  /// tạo controller riêng.
  final MapController? mapController;

  /// Cho phép test truyền provider không gọi mạng (mặc định: tile OSM online).
  final TileProvider? tileProvider;

  /// Chiều cao khung bản đồ.
  final double height;

  /// Zoom khi bay tới một kho được chọn.
  static const double selectedZoom = 14;

  /// Zoom tối đa khi tự canh khung cho toàn bộ kho.
  static const double fitMaxZoom = 13;

  /// URL tile chuẩn của OpenStreetMap.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Bắt buộc theo Tile Usage Policy của OSM.
  static const String osmUserAgentPackageName = 'com.marinelink.marinelink';

  const WarehouseOsmMap({
    super.key,
    required this.warehouses,
    required this.onWarehouseSelected,
    this.selectedWarehouse,
    this.userLocation,
    this.mapController,
    this.tileProvider,
    this.height = 260,
  });

  @override
  State<WarehouseOsmMap> createState() => _WarehouseOsmMapState();
}

class _WarehouseOsmMapState extends State<WarehouseOsmMap> {
  MapController? _internalController;

  MapController get _controller =>
      widget.mapController ?? (_internalController ??= MapController());

  @override
  void didUpdateWidget(covariant WarehouseOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selectedWarehouse;
    if (selected == null) return;
    if (selected.id == oldWidget.selectedWarehouse?.id) return;
    // Toạ độ lấy thẳng từ đối tượng Warehouse đang chọn.
    _controller.move(
      LatLng(selected.latitude, selected.longitude),
      WarehouseOsmMap.selectedZoom,
    );
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final warehouse in widget.warehouses)
        LatLng(warehouse.latitude, warehouse.longitude),
    ];

    return DecoratedBox(
      key: const Key('warehouseOsmMap'),
      decoration: warehouseCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: widget.height,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _averageCenter(points),
              initialZoom: 9,
              initialCameraFit: points.isEmpty
                  ? null
                  : CameraFit.coordinates(
                      coordinates: points,
                      padding: const EdgeInsets.all(48),
                      maxZoom: WarehouseOsmMap.fitMaxZoom,
                    ),
              minZoom: 3,
              maxZoom: 18,
              backgroundColor: AppColors.surfaceSky,
              // Giữ state bản đồ khi cuộn ra khỏi vùng nhìn của ListView, nhờ
              // vậy MapController vẫn gắn với bản đồ và `move()` luôn chạy.
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: WarehouseOsmMap.osmTileUrl,
                userAgentPackageName: WarehouseOsmMap.osmUserAgentPackageName,
                tileProvider: widget.tileProvider,
                maxNativeZoom: 19,
              ),
              MarkerLayer(markers: _buildMarkers()),
              // Ghi công OpenStreetMap — BẮT BUỘC theo Tile Usage Policy.
              // Bọc FittedBox để dòng ghi công không bao giờ tràn trên màn hẹp.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: SimpleAttributionWidget(
                  key: const Key('warehouseOsmAttribution'),
                  source: const Text(AppStrings.openStreetMapAttribution),
                  backgroundColor: Colors.white70,
                  onTap: _openOsmCopyright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final selectedId = widget.selectedWarehouse?.id;
    final userLocation = widget.userLocation;

    return [
      if (userLocation != null)
        Marker(
          key: const Key('warehouseUserLocationMarker'),
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 30,
          height: 30,
          child: const _UserLocationPin(),
        ),
      // MỘT marker cho MỖI kho — không cắt bớt danh sách.
      for (var index = 0; index < widget.warehouses.length; index++)
        _warehouseMarker(
          widget.warehouses[index],
          index: index,
          selected: widget.warehouses[index].id == selectedId,
        ),
    ];
  }

  Marker _warehouseMarker(
    Warehouse warehouse, {
    required int index,
    required bool selected,
  }) {
    final size = selected ? 44.0 : 34.0;
    return Marker(
      key: Key('warehouseMarker_${warehouse.id}'),
      point: LatLng(warehouse.latitude, warehouse.longitude),
      width: size + 12,
      // Đủ chỗ cho vòng tròn + mũi tên chỉ xuống toạ độ.
      height: size + _WarehousePin.pointerSize + 2,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Chạm marker → chọn ĐÚNG đối tượng Warehouse của marker này.
        onTap: () => widget.onWarehouseSelected(warehouse),
        child: _WarehousePin(
          label: '${index + 1}',
          name: warehouse.name,
          selected: selected,
          size: size,
        ),
      ),
    );
  }

  LatLng _averageCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(10.0452, 105.7469);
    var latitude = 0.0;
    var longitude = 0.0;
    for (final point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }
    return LatLng(latitude / points.length, longitude / points.length);
  }

  Future<void> _openOsmCopyright() async {
    await launchUrl(
      Uri.https('www.openstreetmap.org', '/copyright'),
      mode: LaunchMode.externalApplication,
    );
  }
}

/// Ghim tròn kèm số thứ tự cho một kho trên bản đồ OSM.
class _WarehousePin extends StatelessWidget {
  final String label;
  final String name;
  final bool selected;
  final double size;

  /// Chiều cao mũi tên chỉ xuống đúng toạ độ.
  static const double pointerSize = 20;

  const _WarehousePin({
    required this.label,
    required this.name,
    required this.selected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.secondary : AppColors.primary;
    return Semantics(
      label: name,
      selected: selected,
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330B4F8F),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: color, size: pointerSize),
        ],
      ),
    );
  }
}

/// Chấm xanh cho vị trí hiện tại của người dùng.
class _UserLocationPin extends StatelessWidget {
  const _UserLocationPin();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.usingCurrentLocationTitle,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ),
    );
  }
}
