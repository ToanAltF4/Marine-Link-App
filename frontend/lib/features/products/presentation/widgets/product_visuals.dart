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
    'cat-004' => 'H\u1ea3i s\u1ea3n kh\u00f4 cao c\u1ea5p',
    'cat-005' => 'N\u01b0\u1edbc m\u1eafm',
    'cat-fish' => 'C\u00e1',
    'cat-shrimp' => 'T\u00f4m',
    'cat-squid' => 'M\u1ef1c',
    'cat-seafood' => 'H\u1ea3i s\u1ea3n',
    'cat-seasoning' => 'Gia v\u1ecb',
    _ => _localizedCategoryName(category.name),
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
    _ => _localizedProductName(product.name),
  };
}

String displayOrigin(String? origin) {
  return switch (origin) {
    'Phan Thiet' => 'Phan Thi\u1ebft',
    'Ca Mau' => 'C\u00e0 Mau',
    'Phu Quoc' => 'Ph\u00fa Qu\u1ed1c',
    'Vung Tau' => 'V\u0169ng T\u00e0u',
    'Bac Lieu' => 'B\u1ea1c Li\u00eau',
    'Can Tho' => 'C\u1ea7n Th\u01a1',
    'Khanh Hoa' => 'Kh\u00e1nh H\u00f2a',
    'Binh Thuan' => 'B\u00ecnh Thu\u1eadn',
    'Dong Thap' => '\u0110\u1ed3ng Th\u00e1p',
    'Ben Tre' => 'B\u1ebfn Tre',
    'Quang Ngai' => 'Qu\u1ea3ng Ng\u00e3i',
    null => 'Ngu\u1ed3n h\u00e0ng',
    _ => origin,
  };
}

String _localizedCategoryName(String name) {
  return switch (name.trim().toLowerCase()) {
    'muc kho' => 'M\u1ef1c kh\u00f4',
    'tom kho' => 'T\u00f4m kh\u00f4',
    'ca kho' => 'C\u00e1 kh\u00f4',
    'ca dong lanh' => 'C\u00e1 \u0111\u00f4ng l\u1ea1nh',
    'muc mot nang' => 'M\u1ef1c m\u1ed9t n\u1eafng',
    'muc dong lanh' => 'M\u1ef1c \u0111\u00f4ng l\u1ea1nh',
    'tom dong lanh' => 'T\u00f4m \u0111\u00f4ng l\u1ea1nh',
    'nuoc mam' => 'N\u01b0\u1edbc m\u1eafm',
    'hai san kho cao cap' => 'H\u1ea3i s\u1ea3n kh\u00f4 cao c\u1ea5p',
    'ca' => 'C\u00e1',
    'tom' => 'T\u00f4m',
    'muc' => 'M\u1ef1c',
    'hai san' => 'H\u1ea3i s\u1ea3n',
    'gia vi' => 'Gia v\u1ecb',
    _ => name,
  };
}

String _localizedProductName(String name) {
  return switch (name.trim().toLowerCase()) {
    'muc kho loai 1' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 1',
    'muc kho loai 2' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 2',
    'muc kho xe soi' => 'M\u1ef1c kh\u00f4 x\u00e9 s\u1ee3i',
    'tom kho dac biet' => 'T\u00f4m kh\u00f4 \u0111\u1eb7c bi\u1ec7t',
    'tom kho size lon' => 'T\u00f4m kh\u00f4 size l\u1edbn',
    'ca chi vang' => 'C\u00e1 ch\u1ec9 v\u00e0ng',
    'ca basa phi le' => 'C\u00e1 basa phi l\u00ea',
    'ghe dong lanh' => 'Gh\u1eb9 \u0111\u00f4ng l\u1ea1nh',
    'muc mot nang' => 'M\u1ef1c m\u1ed9t n\u1eafng',
    'nuoc mam nhi phu quoc' =>
      'N\u01b0\u1edbc m\u1eafm nh\u0129 Ph\u00fa Qu\u1ed1c',
    _ => name,
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
    'cat-fish' => 'assets/products/dried_yellowstripe_scad.png',
    'cat-shrimp' => 'assets/products/dried_shrimp.png',
    'cat-squid' => 'assets/products/dried_squid.png',
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
    'cat-fish' => Icons.phishing_outlined,
    'cat-shrimp' => Icons.spa_outlined,
    'cat-squid' => Icons.set_meal_outlined,
    'cat-seafood' => Icons.waves_outlined,
    'cat-seasoning' => Icons.water_drop_outlined,
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

Color productStockTextColor(Product product) {
  if (!product.isAvailable) {
    return const Color(0xFFB91C1C); // Red 700
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return const Color(0xFFB45309); // Amber 700
  }
  return const Color(0xFF15803D); // Green 700
}

Color productStockBgColor(Product product) {
  if (!product.isAvailable) {
    return const Color(0xFFFEE2E2); // Red 100
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return const Color(0xFFFEF3C7); // Amber 100
  }
  return const Color(0xFFDCFCE7); // Green 100
}

String productStockLabel(Product product) {
  if (!product.isAvailable) {
    return 'H\u1ebft h\u00e0ng'; // Hết hàng
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return 'S\u1eafp h\u1ebft h\u00e0ng'; // Sắp hết hàng
  }
  return 'C\u00f2n h\u00e0ng'; // Còn hàng
}

String productStockQuantityLabel(Product product) {
  if (!product.isAvailable) {
    return 'H\u1ebft h\u00e0ng'; // Hết hàng
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return 'S\u1eafp h\u1ebft: ${product.stockQuantity}${product.unit}'; // Sắp hết: 60kg
  }
  return 'C\u00f2n h\u00e0ng: ${product.stockQuantity}${product.unit}'; // Còn hàng: 300kg
}
