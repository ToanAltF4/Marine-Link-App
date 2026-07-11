import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

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
    return AppStrings.other;
  }
  return switch (category.id) {
    'cat-001' => AppStrings.driedSquid,
    'cat-002' => AppStrings.driedShrimp,
    'cat-003' => AppStrings.driedFish,
    'cat-004' => AppStrings.premiumDriedSeafood,
    'cat-005' => AppStrings.fishSauce,
    'cat-fish' => AppStrings.fish,
    'cat-shrimp' => AppStrings.shrimp,
    'cat-squid' => AppStrings.squid,
    'cat-seafood' => AppStrings.seafood,
    'cat-seasoning' => AppStrings.seasoning,
    _ => _localizedCategoryName(category.name),
  };
}

String displayProductName(Product product) {
  return switch (product.id) {
    'prod-001' => AppStrings.drySquidGrade1,
    'prod-002' => AppStrings.specialDriedShrimp,
    'prod-003' => AppStrings.yellowstripeScad,
    'prod-004' => AppStrings.semiDriedSquid,
    'prod-005' => AppStrings.shreddedDrySquid,
    'prod-006' => AppStrings.drySquidGrade2,
    'prod-007' => AppStrings.phuQuocFishSauce,
    _ => _localizedProductName(product.name),
  };
}

String displayOrigin(String? origin) {
  return switch (origin) {
    'Phan Thiet' => AppStrings.originPhanThiet,
    'Ca Mau' => AppStrings.originCaMau,
    'Phu Quoc' => AppStrings.originPhuQuoc,
    'Vung Tau' => AppStrings.originVungTau,
    'Bac Lieu' => AppStrings.originBacLieu,
    'Can Tho' => AppStrings.originCanTho,
    'Khanh Hoa' => AppStrings.originKhanhHoa,
    'Binh Thuan' => AppStrings.originBinhThuan,
    'Dong Thap' => AppStrings.originDongThap,
    'Ben Tre' => AppStrings.originBenTre,
    'Quang Ngai' => AppStrings.originQuangNgai,
    null => AppStrings.sourceFallback,
    _ => origin,
  };
}

String _localizedCategoryName(String name) {
  return switch (name.trim().toLowerCase()) {
    'muc kho' => AppStrings.driedSquid,
    'tom kho' => AppStrings.driedShrimp,
    'ca kho' => AppStrings.driedFish,
    'ca dong lanh' => AppStrings.frozenFish,
    'muc mot nang' => AppStrings.semiDriedSquid,
    'muc dong lanh' => AppStrings.frozenSquid,
    'tom dong lanh' => AppStrings.frozenShrimp,
    'nuoc mam' => AppStrings.fishSauce,
    'hai san kho cao cap' => AppStrings.premiumDriedSeafood,
    'ca' => AppStrings.fish,
    'tom' => AppStrings.shrimp,
    'muc' => AppStrings.squid,
    'hai san' => AppStrings.seafood,
    'gia vi' => AppStrings.seasoning,
    _ => name,
  };
}

String _localizedProductName(String name) {
  return switch (name.trim().toLowerCase()) {
    'muc kho loai 1' => AppStrings.drySquidGrade1,
    'muc kho loai 2' => AppStrings.drySquidGrade2,
    'muc kho xe soi' => AppStrings.shreddedDrySquid,
    'tom kho dac biet' => AppStrings.specialDriedShrimp,
    'tom kho size lon' => AppStrings.largeDriedShrimp,
    'ca chi vang' => AppStrings.yellowstripeScad,
    'ca basa phi le' => AppStrings.basaFillet,
    'ghe dong lanh' => AppStrings.frozenCrab,
    'muc mot nang' => AppStrings.semiDriedSquid,
    'nuoc mam nhi phu quoc' => AppStrings.phuQuocFishSauce,
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
    return AppStrings.outOfStock; // Hết hàng
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return AppStrings.lowStockFull; // Sắp hết hàng
  }
  return AppStrings.inStock; // Còn hàng
}

String productStockQuantityLabel(Product product) {
  if (!product.isAvailable) {
    return AppStrings.outOfStock; // Hết hàng
  }
  if (product.stockQuantity <= product.minOrderQuantity * 6) {
    return AppStrings.lowStockQuantity(
      product.stockQuantity,
      product.unit,
    ); // Sắp hết: 60kg
  }
  return AppStrings.availableStockQuantity(
    product.stockQuantity,
    product.unit,
  ); // Còn hàng: 300kg
}
