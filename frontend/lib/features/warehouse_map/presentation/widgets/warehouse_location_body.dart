import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'warehouse_common_widgets.dart';

/// Bố cục nội dung trạng thái quyền vị trí (biểu tượng, tiêu đề, mô tả, hành động).
class WarehouseLocationBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Widget? trailing;

  const WarehouseLocationBody({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WarehouseIconTile(
          icon: icon,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceSky,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              if (action != null) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
