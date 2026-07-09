import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Thanh hiển thị các bộ lọc đang áp dụng kèm nút mở bộ lọc nâng cao.
class ActiveFilterBar extends StatelessWidget {
  final List<String> labels;
  final int activeCount;
  final VoidCallback onFilterTap;

  const ActiveFilterBar({
    super.key,
    required this.labels,
    required this.activeCount,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final filterBtn = AdvancedFilterButton(
      activeCount: activeCount,
      onTap: onFilterTap,
    );

    if (labels.isEmpty) {
      return Align(alignment: Alignment.centerRight, child: filterBtn);
    }

    return Row(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false, scrollbars: false),
            child: SingleChildScrollView(
              key: const Key('productScrollableFilters'),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    ActiveFilterChip(label: labels[i]),
                    if (i < labels.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        filterBtn,
      ],
    );
  }
}

/// Chip nhỏ hiển thị nhãn của một bộ lọc đang được áp dụng.
class ActiveFilterChip extends StatelessWidget {
  final String label;

  const ActiveFilterChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8ACDE8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF00607A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Nút mở bộ lọc nâng cao, hiển thị số lượng bộ lọc đang bật.
class AdvancedFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const AdvancedFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return InkWell(
      key: const Key('productAdvancedFilterButton'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF006A7C) : const Color(0xFFD9E4EF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF006A7C)),
            const SizedBox(width: 6),
            Text(
              'Lọc ($activeCount)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive
                    ? const Color(0xFF006A7C)
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
