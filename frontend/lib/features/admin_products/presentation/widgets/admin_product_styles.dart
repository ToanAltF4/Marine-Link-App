import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Trang trí khung thẻ trắng bo góc dùng chung cho màn quản lý sản phẩm.
final adminProductCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
