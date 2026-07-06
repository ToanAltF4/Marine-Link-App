import 'package:equatable/equatable.dart';

/// Domain entity: Category (embedded in Product).
class Category extends Equatable {
  final String id;
  final String name;

  const Category({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Domain entity: ProductImage.
class ProductImage extends Equatable {
  final String id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [id, imageUrl, displayOrder];
}

/// Domain entity: PriceTier.
/// Represents a wholesale price bracket (e.g. 2–9 kg → 450,000 VND/kg).
class PriceTier extends Equatable {
  final String id;
  final int minQuantity;
  final int? maxQuantity; // null means no upper bound
  final double unitPrice; // VND

  const PriceTier({
    required this.id,
    required this.minQuantity,
    this.maxQuantity,
    required this.unitPrice,
  });

  /// Returns true if [quantity] falls within this tier.
  bool matches(int quantity) {
    if (quantity < minQuantity) return false;
    if (maxQuantity != null && quantity > maxQuantity!) return false;
    return true;
  }

  @override
  List<Object?> get props => [id, minQuantity, maxQuantity, unitPrice];
}

/// Product status values from API.
enum ProductStatus {
  active,
  outOfStock,
  disabled;

  static ProductStatus fromString(String value) {
    return switch (value) {
      'ACTIVE' => ProductStatus.active,
      'OUT_OF_STOCK' => ProductStatus.outOfStock,
      'DISABLED' => ProductStatus.disabled,
      _ => ProductStatus.active,
    };
  }

  String get apiValue => switch (this) {
    ProductStatus.active => 'ACTIVE',
    ProductStatus.outOfStock => 'OUT_OF_STOCK',
    ProductStatus.disabled => 'DISABLED',
  };
}

/// Domain entity: Product (list-view variant — no images/priceTiers).
/// Used for product list screen. Detail variant extends this.
class Product extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? origin;
  final String? imageUrl; // first/thumbnail image
  final double basePrice; // VND
  final String unit; // e.g. "kg"
  final int minOrderQuantity;
  final int stockQuantity;
  final ProductStatus status;
  final bool isFeatured;
  final Category? category;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.origin,
    this.imageUrl,
    required this.basePrice,
    required this.unit,
    required this.minOrderQuantity,
    required this.stockQuantity,
    required this.status,
    this.isFeatured = false,
    this.category,
  });

  bool get isAvailable => status == ProductStatus.active && stockQuantity > 0;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    shortDescription,
    status,
    stockQuantity,
  ];
}

/// Domain entity: ProductDetail — full product with images and price tiers.
/// Returned by GET /api/products/{id}.
class ProductDetail extends Product {
  final String? description;
  final List<ProductImage> images;
  final List<PriceTier> priceTiers;

  const ProductDetail({
    required super.id,
    required super.name,
    required super.slug,
    super.shortDescription,
    super.origin,
    super.imageUrl,
    required super.basePrice,
    required super.unit,
    required super.minOrderQuantity,
    required super.stockQuantity,
    required super.status,
    super.isFeatured,
    super.category,
    this.description,
    this.images = const [],
    this.priceTiers = const [],
  });

  /// Returns the applicable PriceTier for a given quantity, or null.
  PriceTier? tierFor(int quantity) {
    for (final tier in priceTiers) {
      if (tier.matches(quantity)) return tier;
    }
    return null;
  }

  /// Effective unit price for a given quantity.
  double priceFor(int quantity) => tierFor(quantity)?.unitPrice ?? basePrice;

  @override
  List<Object?> get props => [...super.props, description];
}
