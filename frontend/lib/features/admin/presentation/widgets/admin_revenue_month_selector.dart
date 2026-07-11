import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';

/// Month picker + optional day-range filter for the revenue screen.
///
/// The month can move back up to 24 months and never into the future. The
/// day-range pickers are bounded by the same [earliestMonth]..[today] window.
class AdminRevenueMonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime earliestMonth;
  final DateTime currentMonth;
  final DateTime today;
  final bool customRange;
  final DateTime? rangeFrom;
  final DateTime? rangeTo;
  final ValueChanged<DateTime> onSelectMonth;
  final void Function(DateTime from, DateTime to) onSelectRange;
  final VoidCallback onClearRange;

  const AdminRevenueMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.earliestMonth,
    required this.currentMonth,
    required this.today,
    required this.customRange,
    required this.rangeFrom,
    required this.rangeTo,
    required this.onSelectMonth,
    required this.onSelectRange,
    required this.onClearRange,
  });

  bool get _canGoPrev => selectedMonth.isAfter(earliestMonth);
  bool get _canGoNext => selectedMonth.isBefore(currentMonth);

  DateTime get _earliestSelectableDay =>
      DateTime(earliestMonth.year, earliestMonth.month, 1);

  void _goPrev() {
    if (!_canGoPrev) return;
    onSelectMonth(DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
  }

  void _goNext() {
    if (!_canGoNext) return;
    onSelectMonth(DateTime(selectedMonth.year, selectedMonth.month + 1, 1));
  }

  Future<void> _pickFrom(BuildContext context) async {
    final initial = rangeFrom ?? selectedMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(initial),
      firstDate: _earliestSelectableDay,
      lastDate: today,
    );
    if (picked == null) return;
    final to = (rangeTo != null && !rangeTo!.isBefore(picked))
        ? rangeTo!
        : picked;
    onSelectRange(picked, to);
  }

  Future<void> _pickTo(BuildContext context) async {
    final initial = rangeTo ?? selectedMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(initial),
      firstDate: _earliestSelectableDay,
      lastDate: today,
    );
    if (picked == null) return;
    final from = (rangeFrom != null && !rangeFrom!.isAfter(picked))
        ? rangeFrom!
        : picked;
    onSelectRange(from, picked);
  }

  DateTime _clamp(DateTime date) {
    if (date.isBefore(_earliestSelectableDay)) return _earliestSelectableDay;
    if (date.isAfter(today)) return today;
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('adminRevenueMonthSelector'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('adminRevenueMonthPrev'),
                onPressed: _canGoPrev ? _goPrev : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      AppStrings.adminRevenueSelectMonth,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _monthLabel(selectedMonth),
                      key: const Key('adminRevenueMonthLabel'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('adminRevenueMonthNext'),
                onPressed: _canGoNext ? _goNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RangeField(
                  buttonKey: const Key('adminRevenueRangeFrom'),
                  label: AppStrings.adminRevenueFromLabel,
                  value: customRange ? rangeFrom : null,
                  onTap: () => _pickFrom(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RangeField(
                  buttonKey: const Key('adminRevenueRangeTo'),
                  label: AppStrings.adminRevenueToLabel,
                  value: customRange ? rangeTo : null,
                  onTap: () => _pickTo(context),
                ),
              ),
              if (customRange)
                IconButton(
                  key: const Key('adminRevenueClearRange'),
                  tooltip: AppStrings.adminRevenueClearRange,
                  onPressed: onClearRange,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime month) => 'Tháng ${month.month}/${month.year}';
}

class _RangeField extends StatelessWidget {
  final Key buttonKey;
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _RangeField({
    required this.buttonKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value != null ? _dayLabel(value!) : label;
    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onTap,
      icon: const Icon(Icons.event, size: 18),
      label: Text(text, overflow: TextOverflow.ellipsis),
    );
  }

  String _dayLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
