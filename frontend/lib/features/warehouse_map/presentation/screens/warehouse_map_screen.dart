import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/warehouse.dart';
import '../cubit/warehouse_map_cubit.dart';

typedef WarehouseMapLauncher = Future<bool> Function(Warehouse warehouse);

class WarehouseMapScreen extends StatelessWidget {
  final bool staffMode;
  final WarehouseMapLauncher? mapLauncher;

  const WarehouseMapScreen({
    super.key,
    this.staffMode = false,
    this.mapLauncher,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WarehouseMapCubit>(
      create: (_) => sl<WarehouseMapCubit>()..load(),
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
              WarehouseMapStatus.failure => _WarehouseError(
                message: state.errorMessage ?? 'Không tải được danh sách kho.',
                onRetry: () => context.read<WarehouseMapCubit>().load(),
              ),
              WarehouseMapStatus.empty => const _WarehouseEmpty(),
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
        _WarehouseSummary(warehouses: warehouses),
        const SizedBox(height: 14),
        _WarehouseMapPreview(warehouses: warehouses),
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
            child: _WarehouseCard(
              warehouse: warehouse,
              onOpenMaps: () => _openWarehouse(context, warehouse),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWarehouse(BuildContext context, Warehouse warehouse) async {
    final opened = await mapLauncher(warehouse);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không mở được Google Maps.')));
  }
}

class _WarehouseSummary extends StatelessWidget {
  final List<Warehouse> warehouses;

  const _WarehouseSummary({required this.warehouses});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('warehouseSummaryCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.warehouse_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${warehouses.length} kho đang hoạt động',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn kho gần nhất để xem vị trí và mở chỉ đường trên Google Maps.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseMapPreview extends StatelessWidget {
  final List<Warehouse> warehouses;

  const _WarehouseMapPreview({required this.warehouses});

  @override
  Widget build(BuildContext context) {
    final markers = warehouses.take(4).toList();
    return DecoratedBox(
      key: const Key('warehouseMapPreview'),
      decoration: _cardDecoration,
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEAF6FF), Color(0xFFD9F4F2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _MapGrid(),
                ),
              ),
            ),
            Positioned(left: 16, top: 16, child: _MapBadge(label: 'ĐBSCL')),
            for (var i = 0; i < markers.length; i++)
              Align(
                alignment: _markerAlignment(i),
                child: _WarehouseMarker(index: i + 1, name: markers[i].name),
              ),
          ],
        ),
      ),
    );
  }

  Alignment _markerAlignment(int index) {
    return switch (index) {
      0 => const Alignment(-0.35, -0.1),
      1 => const Alignment(0.42, 0.34),
      2 => const Alignment(0.1, -0.48),
      _ => const Alignment(-0.58, 0.52),
    };
  }
}

class _WarehouseMarker extends StatelessWidget {
  final int index;
  final String name;

  const _WarehouseMarker({required this.index, required this.name});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x330B4F8F),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 26),
        ],
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback onOpenMaps;

  const _WarehouseCard({required this.warehouse, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('warehouseCard_${warehouse.id}'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconTile(
                  icon: Icons.location_on_outlined,
                  color: AppColors.secondary,
                  backgroundColor: Color(0xFFE8FBFA),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        warehouse.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (warehouse.openingHours != null)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: warehouse.openingHours!,
                  ),
                if (warehouse.phone != null)
                  _InfoChip(icon: Icons.call_outlined, label: warehouse.phone!),
                _InfoChip(
                  icon: Icons.explore_outlined,
                  label:
                      '${warehouse.latitude.toStringAsFixed(4)}, ${warehouse.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: Key('warehouseOpenMapsButton_${warehouse.id}'),
                onPressed: onOpenMaps,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Mở Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WarehouseError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('warehouseMapError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('warehouseMapRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseEmpty extends StatelessWidget {
  const _WarehouseEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('warehouseMapEmpty'),
      child: AppEmptyState(
        icon: Icons.warehouse_outlined,
        message: 'Chưa có kho hàng đang hoạt động.',
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _MapBadge extends StatelessWidget {
  final String label;

  const _MapBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MapGrid extends StatelessWidget {
  const _MapGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapGridPainter());
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    for (double x = 24; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 24; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.88,
        size.height * 0.34,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<bool> _openGoogleMaps(Warehouse warehouse) {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '${warehouse.latitude},${warehouse.longitude}',
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
