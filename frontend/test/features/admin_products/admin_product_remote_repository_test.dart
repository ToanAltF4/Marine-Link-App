import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_products/data/admin_product_remote_repository.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _product = AdminProduct(
  id: 'product-001',
  name: 'Muc kho',
  slug: 'muc-kho',
  shortDescription: 'Muc size lon cho dai ly',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
);

const _draft = AdminProductDraft(
  categoryId: 'category-001',
  name: 'Muc kho',
  slug: 'muc-kho',
  shortDescription: 'Muc size lon cho dai ly',
  basePrice: 450000,
  unit: 'kg',
  minOrderQuantity: 2,
  stockQuantity: 120,
  status: AdminProductStatus.active,
  isFeatured: true,
);

void main() {
  test(
    'getProducts sends normalized filters to admin products endpoint',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.get<List<AdminProduct>>(
          ApiEndpoints.adminProducts,
          queryParameters: any(named: 'queryParameters'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(success: true, data: [_product]),
      );

      final repository = AdminProductRemoteRepository(apiClient: apiClient);

      final response = await repository.getProducts(
        query: '  muc  ',
        status: AdminProductStatus.disabled,
        featured: false,
      );

      expect(response.data, [_product]);
      final captured =
          verify(
                () => apiClient.get<List<AdminProduct>>(
                  ApiEndpoints.adminProducts,
                  queryParameters: captureAny(named: 'queryParameters'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured, {'q': 'muc', 'status': 'DISABLED', 'featured': false});
    },
  );

  test(
    'createProduct posts draft payload to admin products endpoint',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.post<AdminProduct>(
          ApiEndpoints.adminProducts,
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(success: true, data: _product),
      );

      final repository = AdminProductRemoteRepository(apiClient: apiClient);

      final response = await repository.createProduct(_draft);

      expect(response.data, _product);
      final data =
          verify(
                () => apiClient.post<AdminProduct>(
                  ApiEndpoints.adminProducts,
                  data: captureAny(named: 'data'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data['categoryId'], 'category-001');
      expect(data['shortDescription'], 'Muc size lon cho dai ly');
      expect(data['status'], 'ACTIVE');
      expect(data['isFeatured'], isTrue);
    },
  );

  test(
    'updateProduct and deleteProduct target product detail endpoint',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.put<AdminProduct>(
          ApiEndpoints.adminProductDetail('product-001'),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(success: true, data: _product),
      );
      when(
        () => apiClient.delete(ApiEndpoints.adminProductDetail('product-001')),
      ).thenAnswer((_) async {});

      final repository = AdminProductRemoteRepository(apiClient: apiClient);

      await repository.updateProduct('product-001', _draft);
      final deleteResponse = await repository.deleteProduct('product-001');

      expect(deleteResponse.success, isTrue);
      verify(
        () => apiClient.put<AdminProduct>(
          ApiEndpoints.adminProductDetail('product-001'),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
      verify(
        () => apiClient.delete(ApiEndpoints.adminProductDetail('product-001')),
      ).called(1);
    },
  );
}
