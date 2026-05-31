import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';

class ProductVisualStyle {
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color accentColor;

  const ProductVisualStyle({
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.accentColor,
  });
}

const List<ProductVisualStyle> _productVisualStyles = [
  ProductVisualStyle(
    icon: Icons.set_meal_rounded,
    startColor: Color(0xFF0B4F8F),
    endColor: Color(0xFF1E84C6),
    accentColor: Color(0xFFE0F2FE),
  ),
  ProductVisualStyle(
    icon: Icons.kayaking_rounded,
    startColor: Color(0xFF0F766E),
    endColor: Color(0xFF14B8A6),
    accentColor: Color(0xFFCCFBF1),
  ),
  ProductVisualStyle(
    icon: Icons.waves_rounded,
    startColor: Color(0xFF0F172A),
    endColor: Color(0xFF334155),
    accentColor: Color(0xFFE2E8F0),
  ),
  ProductVisualStyle(
    icon: Icons.ac_unit_rounded,
    startColor: Color(0xFF2563EB),
    endColor: Color(0xFF60A5FA),
    accentColor: Color(0xFFDBEAFE),
  ),
  ProductVisualStyle(
    icon: Icons.sailing_rounded,
    startColor: Color(0xFF155E75),
    endColor: Color(0xFF06B6D4),
    accentColor: Color(0xFFCFFAFE),
  ),
];

ProductVisualStyle productVisualStyle(Product product) {
  final source = product.category?.id ?? product.id;
  final index =
      source.codeUnits.fold<int>(0, (sum, item) => sum + item) %
      _productVisualStyles.length;
  return _productVisualStyles[index];
}

String displayCategoryName(Category? category) {
  if (category == null) {
    return 'Kh\u00e1c';
  }
  return switch (category.id) {
    'cat-001' => 'M\u1ef1c kh\u00f4',
    'cat-002' => 'T\u00f4m kh\u00f4',
    'cat-003' => 'C\u00e1 kh\u00f4',
    'cat-004' => 'M\u1ef1c m\u1ed9t n\u1eafng',
    'cat-005' => 'N\u01b0\u1edbc m\u1eafm',
    _ => category.name,
  };
}

String displayProductName(Product product) {
  return switch (product.id) {
    'prod-001' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 1',
    'prod-002' => 'T\u00f4m kh\u00f4 \u0111\u1eb7c bi\u1ec7t',
    'prod-003' => 'C\u00e1 ch\u1ec9 v\u00e0ng',
    'prod-004' => 'M\u1ef1c m\u1ed9t n\u1eafng',
    'prod-005' => 'M\u1ef1c kh\u00f4 x\u00e9 s\u1ee3i',
    'prod-006' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 2',
    'prod-007' => 'N\u01b0\u1edbc m\u1eafm nh\u0129 Ph\u00fa Qu\u1ed1c',
    _ => product.name,
  };
}

String displayOrigin(String? origin) {
  return switch (origin) {
    'Phan Thiet' => 'Phan Thi\u1ebft',
    'Ca Mau' => 'C\u00e0 Mau',
    'Phu Quoc' => 'Ph\u00fa Qu\u1ed1c',
    'Vung Tau' => 'V\u0169ng T\u00e0u',
    null => 'Ngu\u1ed3n h\u00e0ng',
    _ => origin,
  };
}

ImageProvider<Object>? productImageProvider(Product product) {
  final path = product.imageUrl;
  if (path == null || path.isEmpty) {
    return null;
  }
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return null;
}

String? categoryPreviewAsset(String? categoryId) {
  return switch (categoryId) {
    'cat-001' => 'assets/products/dried_squid.png',
    'cat-002' => 'assets/products/dried_shrimp.png',
    'cat-003' => 'assets/products/dried_yellowstripe_scad.png',
    'cat-004' => 'assets/products/semi_dried_squid.png',
    _ => null,
  };
}

IconData categorySymbolIcon(String? categoryId) {
  return switch (categoryId) {
    'cat-001' => Icons.set_meal_outlined,
    'cat-002' => Icons.spa_outlined,
    'cat-003' => Icons.phishing_outlined,
    'cat-004' => Icons.waves_outlined,
    'cat-005' => Icons.water_drop_outlined,
    _ => Icons.inventory_2_outlined,
  };
}

Color productStockColor(Product product) {
  if (!product.isAvailable) {
    return AppColors.stockOut;
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return AppColors.stockLow;
  }
  return AppColors.stockAvailable;
}

String productStockLabel(Product product) {
  if (!product.isAvailable) {
    return 'S\u1eafp h\u1ebft h\u00e0ng';
  }
  return 'C\u00f2n h\u00e0ng';
}

String productStockQuantityLabel(Product product) {
  if (!product.isAvailable) {
    return 'S\u1eafp h\u1ebft h\u00e0ng';
  }
  return 'C\u00f2n h\u00e0ng: ${product.stockQuantity}${product.unit}';
}
