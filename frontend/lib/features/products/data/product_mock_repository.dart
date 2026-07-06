import '../../../core/api/api_response.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

class ProductMockRepository implements ProductRepository {
  static const _driedSquid = 'assets/products/dried_squid.png';
  static const _driedShrimp = 'assets/products/dried_shrimp.png';
  static const _driedFish = 'assets/products/dried_yellowstripe_scad.png';
  static const _semiDriedSquid = 'assets/products/semi_dried_squid.png';

  static const _driedFishCategory = Category(
    id: 'cat-003',
    name: 'Ca kho',
    parentId: 'cat-fish',
    parentName: 'Cá',
  );
  static const _frozenFishCategory = Category(
    id: 'cat-006',
    name: 'Ca dong lanh',
    parentId: 'cat-fish',
    parentName: 'Cá',
  );
  static const _driedShrimpCategory = Category(
    id: 'cat-002',
    name: 'Tom kho',
    parentId: 'cat-shrimp',
    parentName: 'Tôm',
  );
  static const _frozenShrimpCategory = Category(
    id: 'cat-007',
    name: 'Tom dong lanh',
    parentId: 'cat-shrimp',
    parentName: 'Tôm',
  );
  static const _driedSquidCategory = Category(
    id: 'cat-001',
    name: 'Muc kho',
    parentId: 'cat-squid',
    parentName: 'Mực',
  );
  static const _frozenSquidCategory = Category(
    id: 'cat-008',
    name: 'Muc dong lanh',
    parentId: 'cat-squid',
    parentName: 'Mực',
  );
  static const _premiumSeafoodCategory = Category(
    id: 'cat-004',
    name: 'Hai san kho cao cap',
    parentId: 'cat-seafood',
    parentName: 'Hải sản',
  );
  static const _fishSauceCategory = Category(
    id: 'cat-005',
    name: 'Nuoc mam',
    parentId: 'cat-seasoning',
    parentName: 'Gia vị',
  );

  static const List<Category> _categories = [
    Category(
      id: 'cat-fish',
      name: 'Cá',
      children: [_driedFishCategory, _frozenFishCategory],
    ),
    Category(
      id: 'cat-shrimp',
      name: 'Tôm',
      children: [_driedShrimpCategory, _frozenShrimpCategory],
    ),
    Category(
      id: 'cat-squid',
      name: 'Mực',
      children: [_driedSquidCategory, _frozenSquidCategory],
    ),
    Category(
      id: 'cat-seafood',
      name: 'Hải sản',
      children: [_premiumSeafoodCategory],
    ),
    Category(
      id: 'cat-seasoning',
      name: 'Gia vị',
      children: [_fishSauceCategory],
    ),
  ];

  static final List<Product> _products = [
    Product(
      id: 'prod-001',
      name: 'Muc kho loai 1',
      slug: 'muc-kho-loai-1',
      shortDescription:
          'Size lon, kho deu mau, phu hop dai ly can nguon hang on dinh.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 300,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedSquidCategory,
    ),
    Product(
      id: 'prod-002',
      name: 'Tom kho dac biet',
      slug: 'tom-kho-dac-biet',
      shortDescription:
          'Tom kho mau dep, tien dong goi combo qua bieu va ke dac san.',
      origin: 'Ca Mau',
      imageUrl: _driedShrimp,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 180,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedShrimpCategory,
    ),
    Product(
      id: 'prod-003',
      name: 'Ca chi vang',
      slug: 'ca-chi-vang',
      shortDescription:
          'Ca phoi kho vua do, vi dam, de trung bay cho cua hang dac san.',
      origin: 'Phan Thiet',
      imageUrl: _driedFish,
      basePrice: 280000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 70,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedFishCategory,
    ),
    Product(
      id: 'prod-004',
      name: 'Muc mot nang',
      slug: 'muc-mot-nang',
      shortDescription:
          'Muc thit day, phu hop nha hang va khach san can dong premium.',
      origin: 'Ca Mau',
      imageUrl: _semiDriedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 60,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedSquidCategory,
    ),
    Product(
      id: 'prod-005',
      name: 'Muc kho xe soi',
      slug: 'muc-kho-xe-soi',
      shortDescription:
          'Dang xe soi tien ban le, hop kenh qua tang va dac san cao cap.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 520000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 50,
      status: ProductStatus.active,
      isFeatured: false,
      category: _driedSquidCategory,
    ),
    Product(
      id: 'prod-006',
      name: 'Muc kho loai 2',
      slug: 'muc-kho-loai-2',
      shortDescription:
          'Gia tot cho kenh phan phoi, chat luong on dinh khi trung bay.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: false,
      category: _driedSquidCategory,
    ),
    Product(
      id: 'prod-007',
      name: 'Nuoc mam nhi Phu Quoc',
      slug: 'nuoc-mam-nhi-phu-quoc',
      shortDescription:
          'Dong chai tien loi cho sieu thi mini va cua hang dac san.',
      origin: 'Phu Quoc',
      imageUrl: null,
      basePrice: 180000,
      unit: 'chai',
      minOrderQuantity: 5,
      stockQuantity: 160,
      status: ProductStatus.active,
      isFeatured: false,
      category: _fishSauceCategory,
    ),
  ];

  static final Map<String, ProductDetail> _productDetails = {
    'prod-001': ProductDetail(
      id: 'prod-001',
      name: 'Muc kho loai 1',
      slug: 'muc-kho-loai-1',
      shortDescription:
          'Size lon, kho deu mau, phu hop dai ly can nguon hang on dinh.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 300,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedSquidCategory,
      description:
          'M\u1ef1c kh\u00f4 lo\u1ea1i 1, size l\u1edbn (6-8 con/kg), ph\u01a1i \u0111\u1ee7 n\u1eafng, th\u1ecbt ng\u1ecdt v\u00e0 th\u01a1m. \u0110\u00f3ng g\u00f3i h\u00fat ch\u00e2n kh\u00f4ng 1kg/t\u00fai.',
      images: const [
        ProductImage(
          id: 'img-001-a',
          imageUrl: _driedSquid,
          altText: 'Muc kho loai 1',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-001-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 450000,
        ),
        PriceTier(
          id: 'tier-001-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 427500,
        ),
        PriceTier(
          id: 'tier-001-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 405000,
        ),
      ],
    ),
    'prod-002': ProductDetail(
      id: 'prod-002',
      name: 'Tom kho dac biet',
      slug: 'tom-kho-dac-biet',
      shortDescription:
          'Tom kho mau dep, tien dong goi combo qua bieu va ke dac san.',
      origin: 'Ca Mau',
      imageUrl: _driedShrimp,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 180,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedShrimpCategory,
      description:
          'T\u00f4m kh\u00f4 \u0111\u1eb7c bi\u1ec7t m\u00e0u s\u1eafc '
          '\u0111\u1ed3ng \u0111\u1ec1u, ph\u00f9 h\u1ee3p \u0111\u01a1n '
          '\u0111\u1ea1i l\u00fd v\u00e0 k\u1ec7 combo qu\u00e0 bi\u1ebfu.',
      images: const [
        ProductImage(
          id: 'img-002-a',
          imageUrl: _driedShrimp,
          altText: 'Tom kho dac biet',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-002-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 680000,
        ),
        PriceTier(
          id: 'tier-002-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 650000,
        ),
        PriceTier(
          id: 'tier-002-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 620000,
        ),
      ],
    ),
    'prod-003': ProductDetail(
      id: 'prod-003',
      name: 'Ca chi vang',
      slug: 'ca-chi-vang',
      shortDescription:
          'Ca phoi kho vua do, vi dam, de trung bay cho cua hang dac san.',
      origin: 'Phan Thiet',
      imageUrl: _driedFish,
      basePrice: 280000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 70,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedFishCategory,
      description:
          'Ca chi vang phoi kho vua do, hop cho qua an va cua hang dac san.',
      images: const [
        ProductImage(
          id: 'img-003-a',
          imageUrl: _driedFish,
          altText: 'Ca chi vang',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-003-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 280000,
        ),
        PriceTier(
          id: 'tier-003-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 265000,
        ),
        PriceTier(
          id: 'tier-003-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 250000,
        ),
      ],
    ),
    'prod-004': ProductDetail(
      id: 'prod-004',
      name: 'Muc mot nang',
      slug: 'muc-mot-nang',
      shortDescription:
          'Muc thit day, phu hop nha hang va khach san can dong premium.',
      origin: 'Ca Mau',
      imageUrl: _semiDriedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 60,
      status: ProductStatus.active,
      isFeatured: true,
      category: _driedSquidCategory,
      description:
          'M\u1ef1c m\u1ed9t n\u1eafng th\u1ecbt d\u00e0y, ph\u00f9 '
          'h\u1ee3p k\u00eanh nh\u00e0 h\u00e0ng v\u00e0 kh\u00e1ch '
          's\u1ea1n c\u1ea7n lo\u1ea1i premium.',
      images: const [
        ProductImage(
          id: 'img-004-a',
          imageUrl: _semiDriedSquid,
          altText: 'Muc mot nang',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-004-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 380000,
        ),
        PriceTier(
          id: 'tier-004-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 360000,
        ),
        PriceTier(
          id: 'tier-004-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 345000,
        ),
      ],
    ),
    'prod-005': ProductDetail(
      id: 'prod-005',
      name: 'Muc kho xe soi',
      slug: 'muc-kho-xe-soi',
      shortDescription:
          'Dang xe soi tien ban le, hop kenh qua tang va dac san cao cap.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 520000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 50,
      status: ProductStatus.active,
      isFeatured: false,
      category: _driedSquidCategory,
      description:
          'M\u1ef1c kh\u00f4 x\u00e9 s\u1ee3i ph\u00f9 h\u1ee3p k\u00eanh '
          'qu\u00e0 t\u1eb7ng v\u00e0 c\u1eeda h\u00e0ng \u0111\u1eb7c '
          's\u1ea3n cao c\u1ea5p.',
      images: const [
        ProductImage(
          id: 'img-005-a',
          imageUrl: _driedSquid,
          altText: 'Muc kho xe soi',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-005-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 520000,
        ),
        PriceTier(
          id: 'tier-005-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 500000,
        ),
        PriceTier(
          id: 'tier-005-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 480000,
        ),
      ],
    ),
    'prod-006': ProductDetail(
      id: 'prod-006',
      name: 'Muc kho loai 2',
      slug: 'muc-kho-loai-2',
      shortDescription:
          'Gia tot cho kenh phan phoi, chat luong on dinh khi trung bay.',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: false,
      category: _driedSquidCategory,
      description:
          'M\u1ef1c kh\u00f4 lo\u1ea1i 2 cho k\u00eanh ph\u00e2n '
          'ph\u1ed1i gi\u00e1 t\u1ed1t, v\u1eabn gi\u1eef \u0111\u01b0\u1ee3c '
          '\u0111\u1ed9 \u0111\u1ed3ng \u0111\u1ec1u khi tr\u01b0ng b\u00e0y.',
      images: const [
        ProductImage(
          id: 'img-006-a',
          imageUrl: _driedSquid,
          altText: 'Muc kho loai 2',
          displayOrder: 0,
        ),
      ],
      priceTiers: const [
        PriceTier(
          id: 'tier-006-a',
          minQuantity: 10,
          maxQuantity: 49,
          unitPrice: 380000,
        ),
        PriceTier(
          id: 'tier-006-b',
          minQuantity: 50,
          maxQuantity: 99,
          unitPrice: 360000,
        ),
        PriceTier(
          id: 'tier-006-c',
          minQuantity: 100,
          maxQuantity: null,
          unitPrice: 340000,
        ),
      ],
    ),
    'prod-007': ProductDetail(
      id: 'prod-007',
      name: 'Nuoc mam nhi Phu Quoc',
      slug: 'nuoc-mam-nhi-phu-quoc',
      shortDescription:
          'Dong chai tien loi cho sieu thi mini va cua hang dac san.',
      origin: 'Phu Quoc',
      imageUrl: null,
      basePrice: 180000,
      unit: 'chai',
      minOrderQuantity: 5,
      stockQuantity: 160,
      status: ProductStatus.active,
      isFeatured: false,
      category: _fishSauceCategory,
      description:
          'Nuoc mam nhi dong chai cho kenh sieu thi mini va cua hang dac san.',
      images: const [],
      priceTiers: const [
        PriceTier(
          id: 'tier-007-a',
          minQuantity: 5,
          maxQuantity: 19,
          unitPrice: 180000,
        ),
        PriceTier(
          id: 'tier-007-b',
          minQuantity: 20,
          maxQuantity: 49,
          unitPrice: 170000,
        ),
        PriceTier(
          id: 'tier-007-c',
          minQuantity: 50,
          maxQuantity: null,
          unitPrice: 160000,
        ),
      ],
    ),
  };

  @override
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 0,
    int size = 20,
    String? query,
    String? categoryId,
    bool? featured,
    String? status,
    String? sort,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));

    var filtered = List<Product>.from(_products);

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.origin?.toLowerCase().contains(q) ?? false) ||
                (p.category?.name.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (categoryId != null) {
      filtered = filtered
          .where((p) => _matchesCategory(p.category, categoryId))
          .toList();
    }

    if (featured == true) {
      filtered = filtered.where((p) => p.isFeatured).toList();
    }

    if (status != null) {
      final requestedStatus = ProductStatus.fromString(status);
      filtered = filtered.where((p) => p.status == requestedStatus).toList();
    }

    filtered = _sortProducts(filtered, sort);

    final total = filtered.length;
    final start = page * size;
    final end = (start + size).clamp(0, total);
    final paged = start < total ? filtered.sublist(start, end) : <Product>[];

    return ApiResponse<List<Product>>(
      success: true,
      message: 'OK',
      data: paged,
      pagination: ApiPagination(
        page: page,
        size: size,
        totalElements: total,
        totalPages: (total / size).ceil(),
      ),
    );
  }

  @override
  Future<ApiResponse<List<Category>>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return const ApiResponse<List<Category>>(
      success: true,
      message: 'OK',
      data: _categories,
    );
  }

  @override
  Future<ApiResponse<ProductDetail>> getProductDetail(String productId) async {
    await Future.delayed(const Duration(milliseconds: 10));

    final detail = _productDetails[productId];
    if (detail == null) {
      return const ApiResponse<ProductDetail>(
        success: false,
        message: 'Kh\u00f4ng t\u00ecm th\u1ea5y s\u1ea3n ph\u1ea9m',
        data: null,
      );
    }

    return ApiResponse<ProductDetail>(
      success: true,
      message: 'OK',
      data: detail,
    );
  }

  bool _matchesCategory(Category? category, String categoryId) {
    return category?.id == categoryId || category?.parentId == categoryId;
  }

  List<Product> _sortProducts(List<Product> products, String? sort) {
    final sorted = List<Product>.from(products);
    switch (sort) {
      case 'price':
        sorted.sort((left, right) => left.basePrice.compareTo(right.basePrice));
        break;
      case '-price':
        sorted.sort((left, right) => right.basePrice.compareTo(left.basePrice));
        break;
      case 'name':
        sorted.sort((left, right) => left.name.compareTo(right.name));
        break;
      case '-name':
        sorted.sort((left, right) => right.name.compareTo(left.name));
        break;
      default:
        return products;
    }
    return sorted;
  }
}
