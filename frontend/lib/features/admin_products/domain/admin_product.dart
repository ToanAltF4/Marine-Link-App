import 'package:equatable/equatable.dart';

enum AdminProductStatus {
  active,
  outOfStock,
  disabled;

  static AdminProductStatus fromString(String value) {
    return switch (value.toUpperCase()) {
      'OUT_OF_STOCK' => AdminProductStatus.outOfStock,
      'DISABLED' => AdminProductStatus.disabled,
      _ => AdminProductStatus.active,
    };
  }

  String get apiValue => switch (this) {
    AdminProductStatus.active => 'ACTIVE',
    AdminProductStatus.outOfStock => 'OUT_OF_STOCK',
    AdminProductStatus.disabled => 'DISABLED',
  };
}

class AdminProductCategory extends Equatable {
  final String id;
  final String name;

  const AdminProductCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class AdminProductImage extends Equatable {
  final String id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;

  const AdminProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [id, imageUrl, altText, displayOrder];
}

class AdminPriceTier extends Equatable {
  final String id;
  final int minQuantity;
  final int? maxQuantity;
  final double unitPrice;

  const AdminPriceTier({
    required this.id,
    required this.minQuantity,
    this.maxQuantity,
    required this.unitPrice,
  });

  @override
  List<Object?> get props => [id, minQuantity, maxQuantity, unitPrice];
}

class AdminProductDraft extends Equatable {
  final String categoryId;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? origin;
  final String? imageUrl;
  final double basePrice;
  final String unit;
  final int minOrderQuantity;
  final int stockQuantity;
  final AdminProductStatus status;
  final bool isFeatured;
  final List<AdminPriceTier> priceTiers;

  const AdminProductDraft({
    required this.categoryId,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.origin,
    this.imageUrl,
    required this.basePrice,
    required this.unit,
    required this.minOrderQuantity,
    required this.stockQuantity,
    required this.status,
    required this.isFeatured,
    this.priceTiers = const [],
  });

  @override
  List<Object?> get props => [
    categoryId,
    name,
    slug,
    shortDescription,
    description,
    origin,
    imageUrl,
    basePrice,
    unit,
    minOrderQuantity,
    stockQuantity,
    status,
    isFeatured,
    priceTiers,
  ];
}

class AdminProduct extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? origin;
  final String? imageUrl;
  final double basePrice;
  final String unit;
  final int minOrderQuantity;
  final int stockQuantity;
  final AdminProductStatus status;
  final bool isFeatured;
  final AdminProductCategory? category;
  final List<AdminProductImage> images;
  final List<AdminPriceTier> priceTiers;

  const AdminProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.origin,
    this.imageUrl,
    required this.basePrice,
    required this.unit,
    required this.minOrderQuantity,
    required this.stockQuantity,
    required this.status,
    this.isFeatured = false,
    this.category,
    this.images = const [],
    this.priceTiers = const [],
  });

  String get categoryId => category?.id ?? '';

  AdminProduct copyWith({
    String? id,
    String? name,
    String? slug,
    String? shortDescription,
    String? description,
    String? origin,
    String? imageUrl,
    double? basePrice,
    String? unit,
    int? minOrderQuantity,
    int? stockQuantity,
    AdminProductStatus? status,
    bool? isFeatured,
    AdminProductCategory? category,
    List<AdminProductImage>? images,
    List<AdminPriceTier>? priceTiers,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      unit: unit ?? this.unit,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      category: category ?? this.category,
      images: images ?? this.images,
      priceTiers: priceTiers ?? this.priceTiers,
    );
  }

  AdminProductDraft toDraft() {
    return AdminProductDraft(
      categoryId: categoryId,
      name: name,
      slug: slug,
      shortDescription: shortDescription,
      description: description,
      origin: origin,
      imageUrl: imageUrl,
      basePrice: basePrice,
      unit: unit,
      minOrderQuantity: minOrderQuantity,
      stockQuantity: stockQuantity,
      status: status,
      isFeatured: isFeatured,
      priceTiers: priceTiers,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    shortDescription,
    description,
    origin,
    imageUrl,
    basePrice,
    unit,
    minOrderQuantity,
    stockQuantity,
    status,
    isFeatured,
    category,
    images,
    priceTiers,
  ];
}
