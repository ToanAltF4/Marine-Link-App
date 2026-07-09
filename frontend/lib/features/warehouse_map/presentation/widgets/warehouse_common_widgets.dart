import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Ô biểu tượng vuông bo góc dùng chung cho các thẻ kho hàng.
class WarehouseIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const WarehouseIconTile({
    super.key,
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

/// Khung nền trắng bo góc dùng chung cho các thẻ trên màn kho hàng.
final warehouseCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
