import '../../../core/api/api_response.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

class ProductMockRepository implements ProductRepository {
  static const _driedSquid = 'assets/products/dried_squid.png';
  static const _driedShrimp = 'assets/products/dried_shrimp.png';
  static const _driedFish = 'assets/products/dried_yellowstripe_scad.png';
  static const _semiDriedSquid = 'assets/products/semi_dried_squid.png';

  static final List<Product> _products = [
    Product(
      id: 'prod-001',
      name: 'Muc kho loai 1',
      slug: 'muc-kho-loai-1',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 300,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
    ),
    Product(
      id: 'prod-002',
      name: 'Tom kho dac biet',
      slug: 'tom-kho-dac-biet',
      origin: 'Ca Mau',
      imageUrl: _driedShrimp,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 180,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-002', name: 'Tom kho'),
    ),
    Product(
      id: 'prod-003',
      name: 'Ca chi vang',
      slug: 'ca-chi-vang',
      origin: 'Phan Thiet',
      imageUrl: _driedFish,
      basePrice: 280000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 70,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-003', name: 'Ca kho'),
    ),
    Product(
      id: 'prod-004',
      name: 'Muc mot nang',
      slug: 'muc-mot-nang',
      origin: 'Ca Mau',
      imageUrl: _semiDriedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 60,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-004', name: 'Muc mot nang'),
    ),
    Product(
      id: 'prod-005',
      name: 'Muc kho xe soi',
      slug: 'muc-kho-xe-soi',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 520000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 50,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
    ),
    Product(
      id: 'prod-006',
      name: 'Muc kho loai 2',
      slug: 'muc-kho-loai-2',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
    ),
    Product(
      id: 'prod-007',
      name: 'Nuoc mam nhi Phu Quoc',
      slug: 'nuoc-mam-nhi-phu-quoc',
      origin: 'Phu Quoc',
      imageUrl: null,
      basePrice: 180000,
      unit: 'chai',
      minOrderQuantity: 5,
      stockQuantity: 160,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-005', name: 'Nuoc mam'),
    ),
  ];

  static final Map<String, ProductDetail> _productDetails = {
    'prod-001': ProductDetail(
      id: 'prod-001',
      name: 'Muc kho loai 1',
      slug: 'muc-kho-loai-1',
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 300,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
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
      origin: 'Ca Mau',
      imageUrl: _driedShrimp,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 180,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-002', name: 'Tom kho'),
      description:
          'Tom kho dac biet mau sac dong deu, phu hop don dai ly va ke combo qua bieu.',
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
      origin: 'Phan Thiet',
      imageUrl: _driedFish,
      basePrice: 280000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 70,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-003', name: 'Ca kho'),
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
      origin: 'Ca Mau',
      imageUrl: _semiDriedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 60,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-004', name: 'Muc mot nang'),
      description:
          'Muc mot nang thit day, phu hop kenh nha hang va khach san can loai premium.',
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
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 520000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 50,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
      description:
          'Muc kho xe soi phu hop kenh qua tang va cua hang dac san cao cap.',
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
      origin: 'Phan Thiet',
      imageUrl: _driedSquid,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-001', name: 'Muc kho'),
      description:
          'Muc kho loai 2 cho kenh phan phoi gia tot, van giu duoc do dong deu khi trung bay.',
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
      origin: 'Phu Quoc',
      imageUrl: null,
      basePrice: 180000,
      unit: 'chai',
      minOrderQuantity: 5,
      stockQuantity: 160,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-005', name: 'Nuoc mam'),
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
      filtered = filtered.where((p) => p.category?.id == categoryId).toList();
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
  Future<ApiResponse<ProductDetail>> getProductDetail(String productId) async {
    await Future.delayed(const Duration(milliseconds: 10));

    final detail = _productDetails[productId];
    if (detail == null) {
      return const ApiResponse<ProductDetail>(
        success: false,
        message: 'Khong tim thay san pham',
        data: null,
      );
    }

    return ApiResponse<ProductDetail>(
      success: true,
      message: 'OK',
      data: detail,
    );
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
