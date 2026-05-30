import '../domain/product.dart';

/// DTO: CategoryDto — deserialized from product.category JSON.
class CategoryDto {
  final String id;
  final String name;

  const CategoryDto({required this.id, required this.name});

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Category toDomain() => Category(id: id, name: name);
}

/// DTO: ProductImageDto.
class ProductImageDto {
  final String id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;

  const ProductImageDto({
    required this.id,
    required this.imageUrl,
    this.altText,
    this.displayOrder = 0,
  });

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      altText: json['altText'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  ProductImage toDomain() => ProductImage(
    id: id,
    imageUrl: imageUrl,
    altText: altText,
    displayOrder: displayOrder,
  );
}

/// DTO: PriceTierDto.
class PriceTierDto {
  final String id;
  final int minQuantity;
  final int? maxQuantity;
  final double unitPrice;

  const PriceTierDto({
    required this.id,
    required this.minQuantity,
    this.maxQuantity,
    required this.unitPrice,
  });

  factory PriceTierDto.fromJson(Map<String, dynamic> json) {
    return PriceTierDto(
      id: json['id'] as String,
      minQuantity: json['minQuantity'] as int,
      maxQuantity: json['maxQuantity'] as int?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  PriceTier toDomain() => PriceTier(
    id: id,
    minQuantity: minQuantity,
    maxQuantity: maxQuantity,
    unitPrice: unitPrice,
  );
}

/// DTO: ProductDto — used for product list items (GET /api/products).
class ProductDto {
  final String id;
  final String name;
  final String slug;
  final String? origin;
  final String? imageUrl;
  final double basePrice;
  final String unit;
  final int minOrderQuantity;
  final int stockQuantity;
  final String status;
  final bool isFeatured;
  final CategoryDto? category;

  const ProductDto({
    required this.id,
    required this.name,
    required this.slug,
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

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      origin: json['origin'] as String?,
      imageUrl: json['imageUrl'] as String?,
      basePrice: (json['basePrice'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      minOrderQuantity: json['minOrderQuantity'] as int? ?? 1,
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      isFeatured: json['isFeatured'] as bool? ?? false,
      category: json['category'] != null
          ? CategoryDto.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Product toDomain() => Product(
    id: id,
    name: name,
    slug: slug,
    origin: origin,
    imageUrl: imageUrl,
    basePrice: basePrice,
    unit: unit,
    minOrderQuantity: minOrderQuantity,
    stockQuantity: stockQuantity,
    status: ProductStatus.fromString(status),
    isFeatured: isFeatured,
    category: category?.toDomain(),
  );
}

/// DTO: ProductDetailDto — used for product detail (GET /api/products/{id}).
class ProductDetailDto extends ProductDto {
  final String? description;
  final List<ProductImageDto> images;
  final List<PriceTierDto> priceTiers;

  const ProductDetailDto({
    required super.id,
    required super.name,
    required super.slug,
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

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) {
    final base = ProductDto.fromJson(json);
    return ProductDetailDto(
      id: base.id,
      name: base.name,
      slug: base.slug,
      origin: base.origin,
      imageUrl: base.imageUrl,
      basePrice: base.basePrice,
      unit: base.unit,
      minOrderQuantity: base.minOrderQuantity,
      stockQuantity: base.stockQuantity,
      status: base.status,
      isFeatured: base.isFeatured,
      category: base.category,
      description: json['description'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) =>
                  ProductImageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priceTiers: (json['priceTiers'] as List<dynamic>?)
              ?.map((e) =>
                  PriceTierDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  ProductDetail toDomain() => ProductDetail(
    id: id,
    name: name,
    slug: slug,
    origin: origin,
    imageUrl: imageUrl,
    basePrice: basePrice,
    unit: unit,
    minOrderQuantity: minOrderQuantity,
    stockQuantity: stockQuantity,
    status: ProductStatus.fromString(status),
    isFeatured: isFeatured,
    category: category?.toDomain(),
    description: description,
    images: images.map((e) => e.toDomain()).toList(),
    priceTiers: priceTiers.map((e) => e.toDomain()).toList(),
  );
}

/// Helper to parse list of [ProductDto] from the API response data field.
List<Product> productListFromJson(dynamic json) {
  return (json as List<dynamic>)
      .map((e) => ProductDto.fromJson(e as Map<String, dynamic>).toDomain())
      .toList();
}

/// Helper to parse [ProductDetail] from the API response data field.
ProductDetail productDetailFromJson(dynamic json) {
  return ProductDetailDto.fromJson(json as Map<String, dynamic>).toDomain();
}
