import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/warehouse.dart';
import '../../domain/warehouse_location_service.dart';
import '../../domain/warehouse_user_location.dart';
import '../cubit/warehouse_location_cubit.dart';
import '../cubit/warehouse_map_cubit.dart';
import '../widgets/warehouse_card.dart';
import '../widgets/warehouse_common_widgets.dart';
import '../widgets/warehouse_location_body.dart';
import '../widgets/warehouse_osm_map.dart';
import '../widgets/warehouse_state_widgets.dart';
import '../widgets/warehouse_summary.dart';

typedef WarehouseMapLauncher =
    Future<bool> Function(Warehouse warehouse, WarehouseUserLocation? location);

class WarehouseMapScreen extends StatelessWidget {
  final bool staffMode;
  final WarehouseMapLauncher? mapLauncher;
  final WarehouseLocationService? locationService;

  /// Cho phép test tiêm controller để kiểm tra bản đồ có được yêu cầu `move()`.
  final MapController? mapController;

  /// Cho phép test tiêm tile provider không gọi mạng.
  final TileProvider? tileProvider;

  const WarehouseMapScreen({
    super.key,
    this.staffMode = false,
    this.mapLauncher,
    this.locationService,
    this.mapController,
    this.tileProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WarehouseMapCubit>(
          create: (_) => sl<WarehouseMapCubit>()..load(),
        ),
        BlocProvider<WarehouseLocationCubit>(
          create: (_) => WarehouseLocationCubit(
            service: locationService ?? sl<WarehouseLocationService>(),
          )..loadStatus(),
        ),
      ],
      child: _WarehouseMapView(
        staffMode: staffMode,
        mapLauncher: mapLauncher ?? _openGoogleMaps,
        mapController: mapController,
        tileProvider: tileProvider,
      ),
    );
  }
}

class _WarehouseMapView extends StatelessWidget {
  final bool staffMode;
  final WarehouseMapLauncher mapLauncher;
  final MapController? mapController;
  final TileProvider? tileProvider;

  const _WarehouseMapView({
    required this.staffMode,
    required this.mapLauncher,
    this.mapController,
    this.tileProvider,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      onFirstBack: (context) =>
          context.go(staffMode ? AppRoutes.staffDashboard : AppRoutes.home),
      child: Scaffold(
        key: const Key('warehouseMapScreen'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            key: const Key('warehouseMapBackButton'),
            tooltip: AppStrings.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(
              staffMode ? AppRoutes.staffDashboard : AppRoutes.home,
            ),
          ),
          title: const Text(AppStrings.warehouseTitle),
        ),
        bottomNavigationBar: staffMode
            ? const StaffBottomNav(currentTab: StaffBottomNavTab.work)
            : const BuyerBottomNav(currentTab: BuyerBottomNavTab.home),
        body: BlocBuilder<WarehouseMapCubit, WarehouseMapState>(
          builder: (context, state) {
            return switch (state.status) {
              WarehouseMapStatus.initial ||
              WarehouseMapStatus.loading => const Center(
                key: Key('warehouseMapLoading'),
                child: CircularProgressIndicator(),
              ),
              WarehouseMapStatus.failure => WarehouseError(
                message:
                    state.errorMessage ??
                    AppStrings.warehouseListLoadShortFailed,
                onRetry: () => context.read<WarehouseMapCubit>().load(),
              ),
              WarehouseMapStatus.empty => const WarehouseEmpty(),
              WarehouseMapStatus.success => RefreshIndicator(
                onRefresh: () => context.read<WarehouseMapCubit>().load(),
                child: _WarehouseContent(
                  warehouses: state.warehouses,
                  mapLauncher: mapLauncher,
                  mapController: mapController,
                  tileProvider: tileProvider,
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _WarehouseContent extends StatefulWidget {
  final List<Warehouse> warehouses;
  final WarehouseMapLauncher mapLauncher;
  final MapController? mapController;
  final TileProvider? tileProvider;

  const _WarehouseContent({
    required this.warehouses,
    required this.mapLauncher,
    this.mapController,
    this.tileProvider,
  });

  @override
  State<_WarehouseContent> createState() => _WarehouseContentState();
}

class _WarehouseContentState extends State<_WarehouseContent> {
  /// Kho đang được chọn — dùng CHUNG cho thẻ, marker và nút "Chỉ đường".
  String? _selectedWarehouseId;

  /// Dùng để cuộn thẻ của kho vừa chọn trên bản đồ vào tầm nhìn.
  final Map<String, GlobalKey> _cardKeys = {};

  late final MapController _mapController =
      widget.mapController ?? MapController();

  @override
  void dispose() {
    // Chỉ giải phóng controller do chính màn hình tạo ra.
    if (widget.mapController == null) _mapController.dispose();
    super.dispose();
  }

  Warehouse? get _selectedWarehouse {
    final id = _selectedWarehouseId;
    if (id == null) return null;
    for (final warehouse in widget.warehouses) {
      if (warehouse.id == id) return warehouse;
    }
    return null;
  }

  /// Chọn kho từ thẻ hoặc từ marker — cùng một đối tượng [Warehouse].
  ///
  /// `WarehouseOsmMap` nhận `selectedWarehouse` mới và gọi
  /// `mapController.move(LatLng(w.latitude, w.longitude), 14)` để bay tới đúng
  /// toạ độ của kho đó.
  void _selectWarehouse(Warehouse warehouse, {bool scrollToCard = false}) {
    if (_selectedWarehouseId != warehouse.id) {
      setState(() => _selectedWarehouseId = warehouse.id);
    }
    if (!scrollToCard) return;
    final cardContext = _cardKeys[warehouse.id]?.currentContext;
    if (cardContext == null) return;
    Scrollable.ensureVisible(
      cardContext,
      duration: const Duration(milliseconds: 300),
      alignment: 0.2,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedWarehouse;
    final userLocation = context
        .watch<WarehouseLocationCubit>()
        .state
        .location;

    return ListView(
      key: const Key('warehouseMapList'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        WarehouseSummary(warehouses: widget.warehouses),
        const SizedBox(height: 14),
        const _WarehouseLocationPermissionCard(),
        const SizedBox(height: 14),
        WarehouseOsmMap(
          warehouses: widget.warehouses,
          selectedWarehouse: selected,
          userLocation: userLocation,
          mapController: _mapController,
          tileProvider: widget.tileProvider,
          onWarehouseSelected: (warehouse) =>
              _selectWarehouse(warehouse, scrollToCard: true),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.warehouseMapHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.deliveryPoint,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...widget.warehouses.map(
          (warehouse) => Padding(
            key: _cardKeys.putIfAbsent(warehouse.id, GlobalKey.new),
            padding: const EdgeInsets.only(bottom: 12),
            child: WarehouseCard(
              warehouse: warehouse,
              selected: warehouse.id == _selectedWarehouseId,
              onSelect: () => _selectWarehouse(warehouse),
              onOpenMaps: () => _openWarehouse(context, warehouse),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWarehouse(BuildContext context, Warehouse warehouse) async {
    final location = context.read<WarehouseLocationCubit>().state.location;
    final opened = await widget.mapLauncher(warehouse, location);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.cannotOpenGoogleMaps)),
    );
  }
}

class _WarehouseLocationPermissionCard extends StatelessWidget {
  const _WarehouseLocationPermissionCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseLocationCubit, WarehouseLocationState>(
      builder: (context, state) {
        return DecoratedBox(
          key: const Key('warehouseLocationPermissionCard'),
          decoration: warehouseCardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: switch (state.status) {
              WarehouseLocationStatus.initial ||
              WarehouseLocationStatus.checking => const WarehouseLocationBody(
                key: Key('warehouseLocationChecking'),
                icon: Icons.my_location_outlined,
                title: AppStrings.checkingLocationTitle,
                message: AppStrings.locationChecking,
                trailing: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              WarehouseLocationStatus.granted => WarehouseLocationBody(
                key: const Key('warehouseLocationGranted'),
                icon: Icons.near_me_outlined,
                title: AppStrings.usingCurrentLocationTitle,
                message: AppStrings.currentLocationCoordinates(
                  latitude: state.location!.latitude.toStringAsFixed(4),
                  longitude: state.location!.longitude.toStringAsFixed(4),
                ),
              ),
              WarehouseLocationStatus.denied => WarehouseLocationBody(
                key: const Key('warehouseLocationDenied'),
                icon: Icons.location_disabled_outlined,
                title: AppStrings.locationPermissionNotGranted,
                message: AppStrings.locationPermissionDeniedMessage,
                action: FilledButton.icon(
                  key: const Key('warehouseLocationRequestButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .requestCurrentLocation(),
                  icon: const Icon(Icons.my_location),
                  label: const Text(AppStrings.allowLocation),
                ),
              ),
              WarehouseLocationStatus.deniedForever => WarehouseLocationBody(
                key: const Key('warehouseLocationDeniedForever'),
                icon: Icons.location_off_outlined,
                title: AppStrings.locationPermissionLocked,
                message: AppStrings.locationPermissionSettingsMessage,
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationOpenSettingsButton'),
                  onPressed: () =>
                      context.read<WarehouseLocationCubit>().openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text(AppStrings.openPermissionSettings),
                ),
              ),
              WarehouseLocationStatus.serviceDisabled => WarehouseLocationBody(
                key: const Key('warehouseLocationServiceDisabled'),
                icon: Icons.gps_off_outlined,
                title: AppStrings.locationServiceDisabled,
                message: AppStrings.locationServiceDisabledMessage,
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationOpenLocationSettingsButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .openLocationSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text(AppStrings.openLocationSettings),
                ),
              ),
              WarehouseLocationStatus.failure => WarehouseLocationBody(
                key: const Key('warehouseLocationFailure'),
                icon: Icons.error_outline,
                title: AppStrings.currentLocationUnavailable,
                message: state.errorMessage ?? AppStrings.tryAgainLater,
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationRetryButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .requestCurrentLocation(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

/// Dựng URL Google Maps **chỉ đường tới đúng toạ độ** của cửa hàng.
///
/// Toạ độ (`warehouse.latitude/longitude`) là **nguồn chính xác duy nhất** — lấy
/// từ đúng đối tượng `Warehouse` mà card đang hiển thị, nên card / marker / nút
/// "Chỉ đường" luôn trỏ về cùng một điểm.
///
/// Luôn dùng endpoint **`/maps/dir/`** (chỉ đường) cho MỌI trường hợp. Khi chưa
/// biết vị trí người dùng thì bỏ `origin` — Google Maps tự lấy vị trí hiện tại.
///
/// Trước đây, khi không có vị trí người dùng, code mở `/maps/search/?query=lat,lng`
/// — đó là **tìm kiếm**, nên Google Maps hay "hút" sang địa điểm/cửa hàng gần nhất
/// thay vì ghim đúng toạ độ ⇒ sai điểm đến.
Uri buildWarehouseDirectionsUri(
  Warehouse warehouse,
  WarehouseUserLocation? location,
) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${warehouse.latitude},${warehouse.longitude}',
    if (location != null)
      'origin': '${location.latitude},${location.longitude}',
    'travelmode': 'driving',
  });
}

Future<bool> _openGoogleMaps(
  Warehouse warehouse,
  WarehouseUserLocation? location,
) {
  return launchUrl(
    buildWarehouseDirectionsUri(warehouse, location),
    mode: LaunchMode.externalApplication,
  );
}
