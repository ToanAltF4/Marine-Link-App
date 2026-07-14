import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_products/data/admin_product_remote_repository.dart';
import 'package:marinelink/features/admin_products/domain/admin_product.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _FakeFormData extends Fake implements FormData {}

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
  setUpAll(() {
    registerFallbackValue(_FakeFormData());
  });

  test('getCategories flattens categories from products endpoint', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.get<List<AdminProductCategory>>(
        ApiEndpoints.productCategories,
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        success: true,
        data: [AdminProductCategory(id: 'category-001', name: 'Mực khô')],
      ),
    );

    final repository = AdminProductRemoteRepository(apiClient: apiClient);
    final response = await repository.getCategories();

    expect(response.data?.single.name, 'Mực khô');
    verify(
      () => apiClient.get<List<AdminProductCategory>>(
        ApiEndpoints.productCategories,
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('uploadProductImage posts multipart and returns url', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.postMultipart<String>(
        ApiEndpoints.storageUpload,
        formData: any(named: 'formData'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer(
      (_) async =>
          const ApiResponse(success: true, data: 'https://cdn/muc.png'),
    );

    final repository = AdminProductRemoteRepository(apiClient: apiClient);
    final url = await repository.uploadProductImage(
      bytes: const [1, 2, 3],
      fileName: 'muc.png',
    );

    expect(url, 'https://cdn/muc.png');
    verify(
      () => apiClient.postMultipart<String>(
        ApiEndpoints.storageUpload,
        formData: any(named: 'formData'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

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
        page: 1,
        size: 100,
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
      expect(captured, {
        'q': 'muc',
        'status': 'DISABLED',
        'featured': false,
        'page': 1,
        'size': 100,
      });
    },
  );

  test('getProductDetail targets the product detail endpoint', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.get<AdminProduct>(
        ApiEndpoints.adminProductDetail('product-001'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: _product));

    final repository = AdminProductRemoteRepository(apiClient: apiClient);
    final response = await repository.getProductDetail('product-001');

    expect(response.data, _product);
    verify(
      () => apiClient.get<AdminProduct>(
        ApiEndpoints.adminProductDetail('product-001'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('updateProduct sends every price tier, keeping existing ids', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.put<AdminProduct>(
        ApiEndpoints.adminProductDetail('product-001'),
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: _product));

    final repository = AdminProductRemoteRepository(apiClient: apiClient);
    await repository.updateProduct(
      'product-001',
      const AdminProductDraft(
        categoryId: 'category-001',
        name: 'Muc kho',
        slug: 'muc-kho',
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
          AdminPriceTier(id: '', minQuantity: 10, unitPrice: 420000),
        ],
      ),
    );

    final data =
        verify(
              () => apiClient.put<AdminProduct>(
                ApiEndpoints.adminProductDetail('product-001'),
                data: captureAny(named: 'data'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    final tiers = data['priceTiers'] as List<dynamic>;
    expect(tiers, hasLength(2));
    // Mức giá cũ gửi kèm id -> backend cập nhật tại chỗ (không xoá dòng đang
    // được giỏ hàng tham chiếu); mức giá mới gửi id null.
    expect(tiers[0]['id'], 'tier-001');
    expect(tiers[0]['minQuantity'], 2);
    expect(tiers[1]['id'], isNull);
    expect(tiers[1]['maxQuantity'], isNull);
  });

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
