import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/products/domain/product.dart';
import 'package:marinelink/features/products/presentation/widgets/product_visuals.dart';

void main() {
  group('product visuals', () {
    test('localizes legacy category names from seed data', () {
      expect(
        displayCategoryName(
          const Category(
            id: '550e8400-e29b-41d4-a716-446655440103',
            name: 'Ca dong lanh',
          ),
        ),
        'Cá đông lạnh',
      );
      expect(
        displayCategoryName(const Category(id: 'cat-001', name: 'Muc kho')),
        'Mực khô',
      );
    });

    test('localizes legacy product names from seed data', () {
      final product = Product(
        id: '550e8400-e29b-41d4-a716-446655440113',
        name: 'Ca basa phi le',
        slug: 'ca-basa-phi-le',
        basePrice: 95000,
        unit: 'kg',
        minOrderQuantity: 10,
        stockQuantity: 500,
        status: ProductStatus.active,
      );

      expect(displayProductName(product), 'Cá basa phi lê');
    });
  });
}
