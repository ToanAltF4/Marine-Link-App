import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/warehouse.dart';
import 'warehouse_common_widgets.dart';

/// Bản đồ xem trước dạng minh họa với các điểm đánh dấu vị trí kho.
class WarehouseMapPreview extends StatelessWidget {
  final List<Warehouse> warehouses;

  const WarehouseMapPreview({super.key, required this.warehouses});

  @override
  Widget build(BuildContext context) {
    final markers = warehouses.take(4).toList();
    return DecoratedBox(
      key: const Key('warehouseMapPreview'),
      decoration: warehouseCardDecoration,
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
                  child: MapGrid(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: MapBadge(label: AppStrings.mekongDeltaShort),
            ),
            for (var i = 0; i < markers.length; i++)
              Align(
                alignment: _markerAlignment(i),
                child: WarehouseMarker(index: i + 1, name: markers[i].name),
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

/// Điểm đánh dấu tròn kèm số thứ tự cho một kho trên bản đồ xem trước.
class WarehouseMarker extends StatelessWidget {
  final int index;
  final String name;

  const WarehouseMarker({super.key, required this.index, required this.name});

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

/// Nhãn khu vực nổi trên bản đồ xem trước.
class MapBadge extends StatelessWidget {
  final String label;

  const MapBadge({super.key, required this.label});

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

/// Lưới nền minh họa cho bản đồ xem trước.
class MapGrid extends StatelessWidget {
  const MapGrid({super.key});

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
