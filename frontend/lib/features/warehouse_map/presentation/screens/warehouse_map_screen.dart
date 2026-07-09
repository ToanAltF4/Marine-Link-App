import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/warehouse_map_preview.dart';
import '../widgets/warehouse_state_widgets.dart';
import '../widgets/warehouse_summary.dart';

typedef WarehouseMapLauncher =
    Future<bool> Function(Warehouse warehouse, WarehouseUserLocation? location);

class WarehouseMapScreen extends StatelessWidget {
  final bool staffMode;
  final WarehouseMapLauncher? mapLauncher;
  final WarehouseLocationService? locationService;

  const WarehouseMapScreen({
    super.key,
    this.staffMode = false,
    this.mapLauncher,
    this.locationService,
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
      ),
    );
  }
}

class _WarehouseMapView extends StatelessWidget {
  final bool staffMode;
  final WarehouseMapLauncher mapLauncher;

  const _WarehouseMapView({required this.staffMode, required this.mapLauncher});

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
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(
              staffMode ? AppRoutes.staffDashboard : AppRoutes.home,
            ),
          ),
          title: const Text('Kho hàng'),
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
                message: state.errorMessage ?? 'Không tải được danh sách kho.',
                onRetry: () => context.read<WarehouseMapCubit>().load(),
              ),
              WarehouseMapStatus.empty => const WarehouseEmpty(),
              WarehouseMapStatus.success => _WarehouseContent(
                warehouses: state.warehouses,
                mapLauncher: mapLauncher,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _WarehouseContent extends StatelessWidget {
  final List<Warehouse> warehouses;
  final WarehouseMapLauncher mapLauncher;

  const _WarehouseContent({
    required this.warehouses,
    required this.mapLauncher,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('warehouseMapList'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        WarehouseSummary(warehouses: warehouses),
        const SizedBox(height: 14),
        const _WarehouseLocationPermissionCard(),
        const SizedBox(height: 14),
        WarehouseMapPreview(warehouses: warehouses),
        const SizedBox(height: 16),
        Text(
          'Điểm giao nhận',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...warehouses.map(
          (warehouse) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WarehouseCard(
              warehouse: warehouse,
              onOpenMaps: () => _openWarehouse(context, warehouse),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWarehouse(BuildContext context, Warehouse warehouse) async {
    final location = context.read<WarehouseLocationCubit>().state.location;
    final opened = await mapLauncher(warehouse, location);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không mở được Google Maps.')));
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
                title: 'Đang kiểm tra vị trí',
                message: 'MarineLink đang kiểm tra quyền vị trí hiện tại.',
                trailing: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              WarehouseLocationStatus.granted => WarehouseLocationBody(
                key: const Key('warehouseLocationGranted'),
                icon: Icons.near_me_outlined,
                title: 'Đang dùng vị trí hiện tại',
                message:
                    'Tọa độ ${state.location!.latitude.toStringAsFixed(4)}, '
                    '${state.location!.longitude.toStringAsFixed(4)} sẽ được '
                    'dùng khi mở chỉ đường.',
              ),
              WarehouseLocationStatus.denied => WarehouseLocationBody(
                key: const Key('warehouseLocationDenied'),
                icon: Icons.location_disabled_outlined,
                title: 'Chưa cấp quyền vị trí',
                message:
                    'Bạn vẫn có thể xem danh sách kho và mở Google Maps theo '
                    'từng kho.',
                action: FilledButton.icon(
                  key: const Key('warehouseLocationRequestButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .requestCurrentLocation(),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Cho phép vị trí'),
                ),
              ),
              WarehouseLocationStatus.deniedForever => WarehouseLocationBody(
                key: const Key('warehouseLocationDeniedForever'),
                icon: Icons.location_off_outlined,
                title: 'Quyền vị trí đang bị khóa',
                message:
                    'Hãy mở cài đặt ứng dụng để cấp lại quyền. Danh sách kho '
                    'vẫn dùng được trong lúc này.',
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationOpenSettingsButton'),
                  onPressed: () =>
                      context.read<WarehouseLocationCubit>().openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Mở cài đặt quyền'),
                ),
              ),
              WarehouseLocationStatus.serviceDisabled => WarehouseLocationBody(
                key: const Key('warehouseLocationServiceDisabled'),
                icon: Icons.gps_off_outlined,
                title: 'Vị trí đang tắt',
                message:
                    'Bật dịch vụ vị trí để MarineLink lấy điểm xuất phát. '
                    'Bạn vẫn có thể mở từng kho trên Google Maps.',
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationOpenLocationSettingsButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .openLocationSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Mở cài đặt vị trí'),
                ),
              ),
              WarehouseLocationStatus.failure => WarehouseLocationBody(
                key: const Key('warehouseLocationFailure'),
                icon: Icons.error_outline,
                title: 'Không lấy được vị trí',
                message: state.errorMessage ?? 'Vui lòng thử lại sau.',
                action: OutlinedButton.icon(
                  key: const Key('warehouseLocationRetryButton'),
                  onPressed: () => context
                      .read<WarehouseLocationCubit>()
                      .requestCurrentLocation(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

Future<bool> _openGoogleMaps(
  Warehouse warehouse,
  WarehouseUserLocation? location,
) {
  final uri = location == null
      ? Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${warehouse.latitude},${warehouse.longitude}',
        })
      : Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'origin': '${location.latitude},${location.longitude}',
          'destination': '${warehouse.latitude},${warehouse.longitude}',
          'travelmode': 'driving',
        });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
