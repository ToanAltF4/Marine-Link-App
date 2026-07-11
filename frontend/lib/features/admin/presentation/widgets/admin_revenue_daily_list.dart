import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_revenue.dart';
import 'admin_dashboard_common.dart';

/// Daily revenue dashboard: a simple horizontal-bar list, one row per day.
/// Bars are scaled against the largest day so relative volume is readable
/// without any external chart package.
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            for (final point in series)
              _DailyRow(point: point, maxRevenue: maxRevenue),
          ],
        ),
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyRevenuePoint point;
  final num maxRevenue;

  const _DailyRow({required this.point, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final factor = maxRevenue > 0
        ? (point.revenue / maxRevenue).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              point.date.day.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 18, color: AppColors.surfaceSky),
                  FractionallySizedBox(
                    widthFactor: factor == 0 ? 0.0 : factor,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              MoneyFormatter.compact(point.revenue),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
