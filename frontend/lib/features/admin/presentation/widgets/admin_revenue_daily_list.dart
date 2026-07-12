import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_revenue.dart';
import 'admin_dashboard_common.dart';

/// Biểu đồ doanh thu theo ngày (đường + vùng tô), vẽ bằng CustomPainter —
/// hiển thị xu hướng doanh thu trong khoảng ngày đã chọn (giống mẫu "Trend").
class AdminRevenueDailyList extends StatelessWidget {
  final List<DailyRevenuePoint> series;

  const AdminRevenueDailyList({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return DecoratedBox(
        key: const Key('adminRevenueDailyEmpty'),
        decoration: adminCardDecoration,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(AppStrings.adminRevenueDailyEmpty),
        ),
      );
    }

    num maxRevenue = 0;
    for (final point in series) {
      if (point.revenue > maxRevenue) maxRevenue = point.revenue;
    }

    return DecoratedBox(
      key: const Key('adminRevenueDailyList'),
      decoration: adminCardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mốc doanh thu cao nhất (đầu trục Y).
            Text(
              MoneyFormatter.compact(maxRevenue),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _RevenueTrendPainter(
                  series: series,
                  maxRevenue: maxRevenue.toDouble(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _AxisLabels(series: series),
          ],
        ),
      ),
    );
  }
}

/// Nhãn ngày ở trục X: chỉ hiển thị vài mốc (đầu/giữa/cuối) cho gọn.
class _AxisLabels extends StatelessWidget {
  final List<DailyRevenuePoint> series;

  const _AxisLabels({required this.series});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
    );
    final indices = <int>{
      0,
      series.length ~/ 2,
      series.length - 1,
    }.where((i) => i >= 0 && i < series.length).toList()..sort();

    String fmt(DailyRevenuePoint p) =>
        '${p.date.day.toString().padLeft(2, '0')}/${p.date.month.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final i in indices) Text(fmt(series[i]), style: style),
      ],
    );
  }
}

class _RevenueTrendPainter extends CustomPainter {
  final List<DailyRevenuePoint> series;
  final double maxRevenue;

  _RevenueTrendPainter({required this.series, required this.maxRevenue});

  @override
  void paint(Canvas canvas, Size size) {
    // Lưới ngang nhạt.
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (series.isEmpty) return;

    final n = series.length;
    double xFor(int i) => n == 1 ? size.width / 2 : size.width * i / (n - 1);
    double yFor(num revenue) {
      if (maxRevenue <= 0) return size.height;
      final ratio = (revenue / maxRevenue).clamp(0.0, 1.0);
      // Chừa 8px trên đỉnh cho đẹp.
      return size.height - ratio * (size.height - 8);
    }

    final points = <Offset>[
      for (var i = 0; i < n; i++) Offset(xFor(i), yFor(series[i].revenue)),
    ];

    // Vùng tô dưới đường.
    final areaPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();
    canvas.drawPath(
      areaPath,
      Paint()..color = AppColors.primary.withValues(alpha: 0.14),
    );

    // Đường doanh thu.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Chấm tròn tại các điểm có doanh thu > 0.
    final dotFill = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < n; i++) {
      if (series[i].revenue <= 0) continue;
      canvas.drawCircle(points[i], 3.5, dotFill);
      canvas.drawCircle(points[i], 3.5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter old) =>
      old.series != series || old.maxRevenue != maxRevenue;
}
