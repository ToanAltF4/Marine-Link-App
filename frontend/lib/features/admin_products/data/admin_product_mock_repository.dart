import 'package:marinelink/core/constants/app_strings.dart';
import '../../../core/api/api_response.dart';
import '../domain/admin_product.dart';
import '../domain/admin_product_repository.dart';

class AdminProductMockRepository implements AdminProductRepository {
  final List<AdminProduct> _products;
  var _nextId = 100;

  AdminProductMockRepository({List<AdminProduct>? initialProducts})
    : _products = List.of(initialProducts ?? _sampleProducts);

  @override
  Future<ApiResponse<List<AdminProduct>>> getProducts({
    String? query,
    AdminProductStatus? status,
    bool? featured,
    int? page,
    int? size,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final normalizedQuery = query?.trim().toLowerCase();
    final matches = _products.where((product) {
      final queryMatches =
          normalizedQuery == null ||
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.slug.toLowerCase().contains(normalizedQuery) ||
          (product.origin ?? '').toLowerCase().contains(normalizedQuery);
      final statusMatches = status == null || product.status == status;
      final featuredMatches =
          featured == null || product.isFeatured == featured;
      return queryMatches && statusMatches && featuredMatches;
    }).toList();

    final pageSize = size ?? matches.length;
    final start = (page ?? 0) * pageSize;
    final result = start >= matches.length
        ? <AdminProduct>[]
        : matches.sublist(start, (start + pageSize).clamp(0, matches.length));

    return ApiResponse(success: true, message: 'OK', data: result);
  }

  @override
  Future<ApiResponse<AdminProduct>> getProductDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) {
      return const ApiResponse(
        success: false,
        message: AppStrings.productNotFoundForUpdate,
      );
    }
    return ApiResponse(success: true, message: 'OK', data: _products[index]);
  }

  @override
  Future<ApiResponse<List<AdminProductCategory>>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: _sampleCategories,
    );
  }

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'https://cdn.marinelink.mock/uploads/$fileName';
  }

  @override
  Future<ApiResponse<AdminProduct>> createProduct(
    AdminProductDraft draft,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final validationMessage = _validateDraft(draft);
    if (validationMessage != null) {
      return ApiResponse(success: false, message: validationMessage);
    }
    if (_products.any(
      (product) => product.slug.toLowerCase() == draft.slug.toLowerCase(),
    )) {
      return const ApiResponse(
        success: false,
        message: AppStrings.productSlugExists,
      );
    }

    // Empty category → backend assigns the default category (first active one).
    final category = draft.categoryId.trim().isEmpty
        ? _sampleCategories.first
        : _categoryFromDraft(draft);
    final product = AdminProduct(
      id: 'product-${_nextId++}',
      name: draft.name,
      slug: draft.slug,
      shortDescription: draft.shortDescription,
      description: draft.description,
      origin: draft.origin,
      imageUrl: draft.imageUrl,
      basePrice: draft.basePrice,
      unit: draft.unit,
      minOrderQuantity: draft.minOrderQuantity,
      stockQuantity: draft.stockQuantity,
      status: draft.status,
      isFeatured: draft.isFeatured,
      category: category,
      priceTiers: _tiersWithIds(draft.priceTiers),
    );
    _products.insert(0, product);
    return ApiResponse(success: true, message: 'OK', data: product);
  }

  @override
  Future<ApiResponse<AdminProduct>> updateProduct(
    String id,
    AdminProductDraft draft,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) {
      return const ApiResponse(
        success: false,
        message: AppStrings.productNotFoundForUpdate,
      );
    }
    final validationMessage = _validateDraft(draft);
    if (validationMessage != null) {
      return ApiResponse(success: false, message: validationMessage);
    }
    if (_products.any(
      (product) =>
          product.id != id &&
          product.slug.toLowerCase() == draft.slug.toLowerCase(),
    )) {
      return const ApiResponse(
        success: false,
        message: AppStrings.productSlugExists,
      );
    }

    final existing = _products[index];
    final updated = existing.copyWith(
      name: draft.name,
      slug: draft.slug,
      shortDescription: draft.shortDescription,
      description: draft.description,
      origin: draft.origin,
      imageUrl: draft.imageUrl ?? existing.imageUrl,
      basePrice: draft.basePrice,
      unit: draft.unit,
      minOrderQuantity: draft.minOrderQuantity,
      stockQuantity: draft.stockQuantity,
      status: draft.status,
      isFeatured: draft.isFeatured,
      // Empty category → keep the product's existing category unchanged.
      category: draft.categoryId.trim().isEmpty
          ? existing.category
          : _categoryFromDraft(draft),
      priceTiers: _tiersWithIds(draft.priceTiers),
    );
    _products[index] = updated;
    return ApiResponse(success: true, message: 'OK', data: updated);
  }

  @override
  Future<ApiResponse<void>> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final beforeLength = _products.length;
    _products.removeWhere((product) => product.id == id);
    if (_products.length == beforeLength) {
      return const ApiResponse(
        success: false,
        message: AppStrings.productNotFoundForDelete,
      );
    }
    return const ApiResponse(success: true, message: 'OK');
  }

  AdminProductCategory _categoryFromDraft(AdminProductDraft draft) {
    return _sampleCategories.firstWhere(
      (category) => category.id == draft.categoryId,
      orElse: () => AdminProductCategory(
        id: draft.categoryId,
        name: AppStrings.customCategoryName,
      ),
    );
  }

  List<AdminPriceTier> _tiersWithIds(List<AdminPriceTier> tiers) {
    return [
      for (var i = 0; i < tiers.length; i++)
        AdminPriceTier(
          id: tiers[i].id.isEmpty ? 'tier-${_nextId + i}' : tiers[i].id,
          minQuantity: tiers[i].minQuantity,
          maxQuantity: tiers[i].maxQuantity,
          unitPrice: tiers[i].unitPrice,
        ),
    ];
  }

  String? _validateDraft(AdminProductDraft draft) {
    // Category is optional: empty means the backend picks a default (create)
    // or keeps the existing category (update).
    if (draft.name.trim().isEmpty) return AppStrings.productNameRequired;
    if (draft.slug.trim().isEmpty) return AppStrings.slugRequired;
    if (draft.basePrice <= 0) return AppStrings.basePriceMustBePositive;
    if (draft.minOrderQuantity <= 0) {
      return AppStrings.minQuantityMustBePositive;
    }
    if (draft.stockQuantity < 0) return AppStrings.stockMustNotBeNegative;

    final tiers = List<AdminPriceTier>.of(draft.priceTiers)
      ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
    int? previousMax;
    for (var index = 0; index < tiers.length; index++) {
      final tier = tiers[index];
      if (tier.minQuantity <= 0 || tier.unitPrice <= 0) {
        return AppStrings.wholesaleTierInvalid;
      }
      if (tier.maxQuantity != null && tier.maxQuantity! < tier.minQuantity) {
        return AppStrings.wholesaleTierInvalid;
      }
      if (previousMax != null && tier.minQuantity <= previousMax) {
        return AppStrings.wholesaleTierDuplicated;
      }
      if (previousMax == null && index > 0) {
        return AppStrings.wholesaleTierDuplicated;
      }
      previousMax = tier.maxQuantity;
    }
    return null;
  }
}

const _sampleCategories = [
  AdminProductCategory(
    id: '550e8400-e29b-41d4-a716-446655440004',
    name: AppStrings.driedSquid,
  ),
  AdminProductCategory(
    id: '550e8400-e29b-41d4-a716-446655440005',
    name: AppStrings.driedShrimp,
  ),
  AdminProductCategory(
    id: '550e8400-e29b-41d4-a716-446655440006',
    name: AppStrings.driedFish,
  ),
];

final _sampleProducts = [
  AdminProduct(
    id: 'product-001',
    name: AppStrings.drySquidGrade1,
    slug: 'muc-kho-loai-1',
    description: AppStrings.wholesaleDrySquidDescription,
    origin: AppStrings.originCaMau,
    imageUrl: 'assets/products/dried_squid.png',
    basePrice: 450000,
    unit: 'kg',
    minOrderQuantity: 2,
    stockQuantity: 120,
    status: AdminProductStatus.active,
    isFeatured: true,
    category: _sampleCategories[0],
    priceTiers: [
      AdminPriceTier(
        id: 'tier-001',
        minQuantity: 2,
        maxQuantity: 9,
        unitPrice: 450000,
      ),
      AdminPriceTier(id: 'tier-002', minQuantity: 10, unitPrice: 420000),
    ],
  ),
  AdminProduct(
    id: 'product-002',
    name: AppStrings.largeDriedShrimp,
    slug: 'tom-kho-size-lon',
    description: AppStrings.wholesaleDriedShrimpDescription,
    origin: AppStrings.originBacLieu,
    imageUrl: 'assets/products/dried_shrimp.png',
    basePrice: 680000,
    unit: 'kg',
    minOrderQuantity: 1,
    stockQuantity: 8,
    status: AdminProductStatus.outOfStock,
    isFeatured: false,
    category: _sampleCategories[1],
  ),
  AdminProduct(
    id: 'product-003',
    name: AppStrings.yellowstripeScad,
    slug: 'ca-chi-vang',
    description: AppStrings.hiddenProductDescription,
    origin: AppStrings.originPhanThiet,
    imageUrl: 'assets/products/dried_yellowstripe_scad.png',
    basePrice: 240000,
    unit: 'kg',
    minOrderQuantity: 3,
    stockQuantity: 0,
    status: AdminProductStatus.disabled,
    isFeatured: false,
    category: _sampleCategories[2],
  ),
];
