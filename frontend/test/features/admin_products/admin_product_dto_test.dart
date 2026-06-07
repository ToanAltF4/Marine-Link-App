import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/admin_products/data/admin_product_dto.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';

void main() {
  test('adminProductFromJson parses full payload', () {
    final product = adminProductFromJson({
      'id': 'product-001',
      'name': 'Mực khô loại 1',
      'slug': 'muc-kho-loai-1',
      'description': 'Mực khô phục vụ đơn sỉ',
      'origin': 'Cà Mau',
      'imageUrl': 'https://example.com/muc.png',
      'basePrice': 450000,
      'unit': 'kg',
      'minOrderQuantity': 2,
      'stockQuantity': 120,
      'status': 'ACTIVE',
      'isFeatured': true,
      'category': {'id': 'category-001', 'name': 'Mực khô'},
      'images': [
        {
          'id': 'image-001',
          'imageUrl': 'https://example.com/muc.png',
          'altText': 'Mực khô',
          'displayOrder': 0,
        },
      ],
      'priceTiers': [
        {
          'id': 'tier-001',
          'minQuantity': 2,
          'maxQuantity': 9,
          'unitPrice': 450000,
        },
      ],
    });

    expect(product.id, 'product-001');
    expect(product.name, 'Mực khô loại 1');
    expect(product.status, AdminProductStatus.active);
    expect(product.isFeatured, isTrue);
    expect(product.category?.name, 'Mực khô');
    expect(product.images.single.displayOrder, 0);
    expect(product.priceTiers.single.unitPrice, 450000);
  });

  test('adminProductFromJson tolerates missing fields', () {
    final product = adminProductFromJson({
      'publicId': 'product-002',
      'name': 'Tôm khô',
      'basePrice': 680000,
    });

    expect(product.id, 'product-002');
    expect(product.slug, '');
    expect(product.unit, 'kg');
    expect(product.minOrderQuantity, 1);
    expect(product.stockQuantity, 0);
    expect(product.status, AdminProductStatus.active);
    expect(product.images, isEmpty);
  });

  test('adminProductFromJson parses numeric strings', () {
    final product = adminProductFromJson({
      'id': 123,
      'name': 'Cá chỉ vàng',
      'basePrice': '240000',
      'minOrderQuantity': '3',
      'stockQuantity': '12',
      'status': 'DISABLED',
      'isFeatured': 'true',
      'priceTiers': [
        {
          'id': 1,
          'minQuantity': '3',
          'maxQuantity': '10',
          'unitPrice': '220000',
        },
      ],
    });

    expect(product.id, '123');
    expect(product.basePrice, 240000);
    expect(product.minOrderQuantity, 3);
    expect(product.stockQuantity, 12);
    expect(product.status, AdminProductStatus.disabled);
    expect(product.isFeatured, isTrue);
    expect(product.priceTiers.single.maxQuantity, 10);
  });

  test('adminProductsFromJson parses common collection wrappers', () {
    final products = adminProductsFromJson({
      'content': [
        {'id': 'product-001', 'name': 'Mực khô', 'basePrice': 450000},
      ],
    });

    expect(products, hasLength(1));
    expect(products.single.name, 'Mực khô');
  });

  test('adminProductDraftToJson writes contract fields only', () {
    final json = adminProductDraftToJson(
      const AdminProductDraft(
        categoryId: 'category-001',
        name: 'Mực khô',
        slug: 'muc-kho',
        description: 'Mô tả',
        origin: 'Cà Mau',
        basePrice: 450000,
        unit: 'kg',
        minOrderQuantity: 2,
        stockQuantity: 120,
        status: AdminProductStatus.active,
        isFeatured: true,
        priceTiers: [
          AdminPriceTier(
            id: 'tier-001',
            minQuantity: 2,
            maxQuantity: 9,
            unitPrice: 450000,
          ),
        ],
      ),
    );

    expect(json['categoryId'], 'category-001');
    expect(json['status'], 'ACTIVE');
    expect(json.containsKey('imageUrl'), isFalse);
    expect(json['priceTiers'], hasLength(1));
  });
}
