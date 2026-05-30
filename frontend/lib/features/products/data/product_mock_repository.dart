import '../domain/product.dart';
import '../domain/product_repository.dart';
import '../../../core/api/api_response.dart';

/// Mock ProductRepository for Sprint 1.
/// Returns hard-coded seafood data for demo/testing.
/// Replace with ProductRemoteRepository in Sprint 5 via DI — no UI changes needed.
class ProductMockRepository implements ProductRepository {
  static final List<Product> _products = [
    Product(
      id: 'prod-001',
      name: 'Mực khô loại 1',
      slug: 'muc-kho-loai-1',
      origin: 'Cà Mau',
      imageUrl: null,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 2,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-001', name: 'Mực khô'),
    ),
    Product(
      id: 'prod-002',
      name: 'Tôm khô size lớn',
      slug: 'tom-kho-size-lon',
      origin: 'Bạc Liêu',
      imageUrl: null,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 1,
      stockQuantity: 80,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-002', name: 'Tôm khô'),
    ),
    Product(
      id: 'prod-003',
      name: 'Cá khô dứa',
      slug: 'ca-kho-dua',
      origin: 'Kiên Giang',
      imageUrl: null,
      basePrice: 320000,
      unit: 'kg',
      minOrderQuantity: 2,
      stockQuantity: 200,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-003', name: 'Cá khô'),
    ),
    Product(
      id: 'prod-004',
      name: 'Ghẹ đông lạnh',
      slug: 'ghe-dong-lanh',
      origin: 'Phú Quốc',
      imageUrl: null,
      basePrice: 250000,
      unit: 'kg',
      minOrderQuantity: 5,
      stockQuantity: 0,
      status: ProductStatus.outOfStock,
      isFeatured: false,
      category: const Category(id: 'cat-004', name: 'Ghẹ & Cua'),
    ),
    Product(
      id: 'prod-005',
      name: 'Cá basa phi lê',
      slug: 'ca-basa-phi-le',
      origin: 'An Giang',
      imageUrl: null,
      basePrice: 95000,
      unit: 'kg',
      minOrderQuantity: 10,
      stockQuantity: 500,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-005', name: 'Cá đông lạnh'),
    ),
    Product(
      id: 'prod-006',
      name: 'Tôm sú đông lạnh',
      slug: 'tom-su-dong-lanh',
      origin: 'Sóc Trăng',
      imageUrl: null,
      basePrice: 380000,
      unit: 'kg',
      minOrderQuantity: 3,
      stockQuantity: 150,
      status: ProductStatus.active,
      isFeatured: false,
      category: const Category(id: 'cat-006', name: 'Tôm đông lạnh'),
    ),
  ];

  static final Map<String, ProductDetail> _productDetails = {
    'prod-001': ProductDetail(
      id: 'prod-001',
      name: 'Mực khô loại 1',
      slug: 'muc-kho-loai-1',
      origin: 'Cà Mau',
      imageUrl: null,
      basePrice: 450000,
      unit: 'kg',
      minOrderQuantity: 2,
      stockQuantity: 120,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-001', name: 'Mực khô'),
      description:
          'Mực khô loại 1 từ vùng biển Cà Mau, phù hợp đơn sỉ nhà hàng. Hương vị đậm đà, thịt dày, bảo quản tốt.',
      images: const [],
      priceTiers: const [
        PriceTier(
          id: 'tier-001-a',
          minQuantity: 2,
          maxQuantity: 9,
          unitPrice: 450000,
        ),
        PriceTier(
          id: 'tier-001-b',
          minQuantity: 10,
          maxQuantity: null,
          unitPrice: 420000,
        ),
      ],
    ),
    'prod-002': ProductDetail(
      id: 'prod-002',
      name: 'Tôm khô size lớn',
      slug: 'tom-kho-size-lon',
      origin: 'Bạc Liêu',
      imageUrl: null,
      basePrice: 680000,
      unit: 'kg',
      minOrderQuantity: 1,
      stockQuantity: 80,
      status: ProductStatus.active,
      isFeatured: true,
      category: const Category(id: 'cat-002', name: 'Tôm khô'),
      description:
          'Tôm khô size lớn Bạc Liêu, màu đỏ tươi tự nhiên, thịt chắc ngọt. Thích hợp để bún, cháo, nấu canh.',
      images: const [],
      priceTiers: const [
        PriceTier(
          id: 'tier-002-a',
          minQuantity: 1,
          maxQuantity: 4,
          unitPrice: 680000,
        ),
        PriceTier(
          id: 'tier-002-b',
          minQuantity: 5,
          maxQuantity: null,
          unitPrice: 650000,
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
    await Future.delayed(const Duration(milliseconds: 400));

    var filtered = List<Product>.from(_products);

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.origin?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (categoryId != null) {
      filtered =
          filtered.where((p) => p.category?.id == categoryId).toList();
    }

    if (featured == true) {
      filtered = filtered.where((p) => p.isFeatured).toList();
    }

    if (status != null) {
      final s = ProductStatus.fromString(status);
      filtered = filtered.where((p) => p.status == s).toList();
    }

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
  Future<ApiResponse<ProductDetail>> getProductDetail(
    String productId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final detail = _productDetails[productId];
    if (detail == null) {
      return const ApiResponse<ProductDetail>(
        success: false,
        message: 'Không tìm thấy sản phẩm',
        data: null,
      );
    }

    return ApiResponse<ProductDetail>(
      success: true,
      message: 'OK',
      data: detail,
    );
  }
}
