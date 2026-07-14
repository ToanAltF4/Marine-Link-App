import '../domain/admin_product.dart';

List<AdminProduct> adminProductsFromJson(dynamic json) {
  final rawItems = switch (json) {
    {'items': final List<dynamic> items} => items,
    {'content': final List<dynamic> content} => content,
    {'products': final List<dynamic> products} => products,
    final List<dynamic> list => list,
    _ => const <dynamic>[],
  };

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(adminProductFromJson)
      .toList();
}

AdminProduct adminProductFromJson(dynamic json) {
  final map = json as Map<String, dynamic>;
  final category = _categoryFromJson(map['category']);
  return AdminProduct(
    id: _idFromJson(map),
    name: _stringOrEmpty(map['name']),
    slug: _stringOrEmpty(map['slug']),
    shortDescription: _stringOrNull(map['shortDescription']),
    description: _stringOrNull(map['description']),
    origin: _stringOrNull(map['origin']),
    imageUrl: _stringOrNull(map['imageUrl']),
    basePrice: _toNum(map['basePrice']).toDouble(),
    unit: _stringOrEmpty(map['unit']).isEmpty
        ? 'kg'
        : _stringOrEmpty(map['unit']),
    minOrderQuantity: _toInt(map['minOrderQuantity'], fallback: 1),
    stockQuantity: _toInt(map['stockQuantity']),
    status: AdminProductStatus.fromString(_stringOrEmpty(map['status'])),
    isFeatured: _toBool(map['isFeatured']),
    category: category,
    images: _imagesFromJson(map['images']),
    priceTiers: _priceTiersFromJson(map['priceTiers']),
  );
}

Map<String, dynamic> adminProductDraftToJson(AdminProductDraft draft) {
  return {
    // Empty means "no category selected" → let the backend assign a default
    // (create) or keep the existing category (update).
    'categoryId': draft.categoryId.trim().isEmpty ? null : draft.categoryId,
    'name': draft.name,
    'slug': draft.slug,
    'shortDescription': draft.shortDescription,
    'description': draft.description,
    'origin': draft.origin,
    'imageUrl': draft.imageUrl,
    'basePrice': draft.basePrice,
    'unit': draft.unit,
    'minOrderQuantity': draft.minOrderQuantity,
    'stockQuantity': draft.stockQuantity,
    'status': draft.status.apiValue,
    'isFeatured': draft.isFeatured,
    'priceTiers': draft.priceTiers
        .map(
          (tier) => {
            // Existing tiers send their public id so the backend updates that
            // row in place instead of dropping and recreating it (which would
            // break carts referencing the tier). New tiers send id = null.
            'id': tier.id.trim().isEmpty ? null : tier.id,
            'minQuantity': tier.minQuantity,
            'maxQuantity': tier.maxQuantity,
            'unitPrice': tier.unitPrice,
          },
        )
        .toList(),
  };
}

/// Flatten the (possibly nested) category tree returned by
/// `GET /api/products/categories` into a flat list of selectable categories.
List<AdminProductCategory> adminCategoriesFromJson(dynamic json) {
  final rawItems = switch (json) {
    {'items': final List<dynamic> items} => items,
    {'content': final List<dynamic> content} => content,
    final List<dynamic> list => list,
    _ => const <dynamic>[],
  };

  final result = <AdminProductCategory>[];
  final seen = <String>{};
  void collect(Iterable<dynamic> nodes) {
    for (final node in nodes.whereType<Map<String, dynamic>>()) {
      final category = _categoryFromJson(node);
      if (category != null && category.id.isNotEmpty && seen.add(category.id)) {
        result.add(category);
      }
      final children = node['children'];
      if (children is List<dynamic>) {
        collect(children);
      }
    }
  }

  collect(rawItems);
  return result;
}

/// Extract the public image URL from the storage upload response payload.
String uploadedImageUrlFromJson(dynamic json) {
  if (json is Map<String, dynamic>) {
    return _stringOrEmpty(json['url']);
  }
  return '';
}

AdminProductCategory? _categoryFromJson(dynamic value) {
  if (value is! Map<String, dynamic>) return null;
  return AdminProductCategory(
    id: _idFromJson(value),
    name: _stringOrEmpty(value['name']),
  );
}

List<AdminProductImage> _imagesFromJson(dynamic value) {
  if (value is! List<dynamic>) return const [];
  return value.whereType<Map<String, dynamic>>().map((map) {
    return AdminProductImage(
      id: _idFromJson(map),
      imageUrl: _stringOrEmpty(map['imageUrl']),
      altText: _stringOrNull(map['altText']),
      displayOrder: _toInt(map['displayOrder']),
    );
  }).toList();
}

List<AdminPriceTier> _priceTiersFromJson(dynamic value) {
  if (value is! List<dynamic>) return const [];
  return value.whereType<Map<String, dynamic>>().map((map) {
    return AdminPriceTier(
      id: _idFromJson(map),
      minQuantity: _toInt(map['minQuantity'], fallback: 1),
      maxQuantity: map['maxQuantity'] == null
          ? null
          : _toInt(map['maxQuantity']),
      unitPrice: _toNum(map['unitPrice']).toDouble(),
    );
  }).toList();
}

String _idFromJson(Map<String, dynamic> map) {
  final raw = map['id'] ?? map['publicId'] ?? map['public_id'];
  if (raw == null) return '';
  if (raw is num) return _toInt(raw).toString();
  return raw.toString();
}

String _stringOrEmpty(dynamic value) => _stringOrNull(value) ?? '';

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) {
    final parsed = _toNum(value);
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
