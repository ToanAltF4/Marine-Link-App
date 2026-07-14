import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_products/data/admin_product_mock_repository.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';

void main() {
  test('getProducts returns success and sample data', () async {
    final repository = AdminProductMockRepository();

    final response = await repository.getProducts();

    expect(response.success, isTrue);
    expect(response.data, isNotNull);
    expect(response.data, isNotEmpty);
  });

  test('filters products by status and featured flag', () async {
    final repository = AdminProductMockRepository(
      initialProducts: const [_activeProduct, _disabledProduct],
    );

    final response = await repository.getProducts(
      status: AdminProductStatus.active,
      featured: true,
    );

    expect(response.success, isTrue);
    expect(response.data, [_activeProduct]);
  });

  test('createProduct adds a valid product', () async {
    final repository = AdminProductMockRepository(initialProducts: const []);

    final response = await repository.createProduct(_draft('muc-kho-moi'));

    expect(response.success, isTrue);
    expect(response.data?.slug, 'muc-kho-moi');

    final list = await repository.getProducts();
    expect(list.data, hasLength(1));
  });

  test('updateProduct changes editable fields', () async {
    final repository = AdminProductMockRepository(
      initialProducts: const [_activeProduct],
    );

    final response = await repository.updateProduct(
      _activeProduct.id,
      _draft('muc-kho-cap-nhat').copyWithName('Mực khô cập nhật'),
    );

    expect(response.success, isTrue);
    expect(response.data?.name, 'Mực khô cập nhật');
    expect(response.data?.slug, 'muc-kho-cap-nhat');
  });

  test('deleteProduct removes product from admin list', () async {
    final repository = AdminProductMockRepository(
      initialProducts: const [_activeProduct],
    );

    final response = await repository.deleteProduct(_activeProduct.id);
    final list = await repository.getProducts();

    expect(response.success, isTrue);
    expect(list.data, isEmpty);
  });

  test('rejects duplicate slug and overlapping tiers', () async {
    final repository = AdminProductMockRepository(
      initialProducts: const [_activeProduct],
    );

    final duplicate = await repository.createProduct(
      _draft(_activeProduct.slug),
    );
    expect(duplicate.success, isFalse);

    final overlap = await repository.createProduct(
      _draft('muc-kho-overlap').copyWithTiers(const [
        AdminPriceTier(
          id: '',
          minQuantity: 2,
          maxQuantity: 9,
          unitPrice: 450000,
        ),
        AdminPriceTier(id: '', minQuantity: 9, unitPrice: 420000),
      ]),
    );
    expect(overlap.success, isFalse);
  });
}

const _category = AdminProductCategory(id: 'category-001', name: 'Mực khô');

const _activeProduct = AdminProduct(
  id: 'product-001',
  name: 'Mực khô loại 1',
  slug: 'muc-kho-loai-1',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
  isFeatured: true,
  category: _category,
);

const _disabledProduct = AdminProduct(
  id: 'product-002',
  name: 'Cá chỉ vàng',
  slug: 'ca-chi-vang',
  basePrice: 240000,
  unit: 'kg',
  minOrderQuantity: 3,
  stockQuantity: 0,
  status: AdminProductStatus.disabled,
  category: _category,
);

AdminProductDraft _draft(String slug) => AdminProductDraft(
  categoryId: _category.id,
  name: 'Mực khô mới',
  slug: slug,
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
  isFeatured: true,
  priceTiers: const [
    AdminPriceTier(id: '', minQuantity: 2, maxQuantity: 9, unitPrice: 450000),
  ],
);

extension on AdminProductDraft {
  AdminProductDraft copyWithName(String name) {
    return AdminProductDraft(
      categoryId: categoryId,
      name: name,
      slug: slug,
      description: description,
      origin: origin,
      basePrice: basePrice,
      unit: unit,
      minOrderQuantity: minOrderQuantity,
      stockQuantity: stockQuantity,
      status: status,
      isFeatured: isFeatured,
      priceTiers: priceTiers,
    );
  }

  AdminProductDraft copyWithTiers(List<AdminPriceTier> tiers) {
    return AdminProductDraft(
      categoryId: categoryId,
      name: name,
      slug: slug,
      description: description,
      origin: origin,
      basePrice: basePrice,
      unit: unit,
      minOrderQuantity: minOrderQuantity,
      stockQuantity: stockQuantity,
      status: status,
      isFeatured: isFeatured,
      priceTiers: tiers,
    );
  }
}
