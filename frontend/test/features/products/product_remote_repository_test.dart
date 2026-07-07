import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/core/storage/secure_token_storage.dart';
import 'package:marinelink/features/products/data/product_remote_repository.dart';

void main() {
  group('ProductRemoteRepository cache', () {
    test('reuses identical product list responses in memory', () async {
      final apiClient = _FakeApiClient();
      final repository = ProductRemoteRepository(apiClient: apiClient);

      final first = await repository.getProducts(
        page: 0,
        size: 20,
        status: 'ACTIVE',
      );
      final second = await repository.getProducts(
        page: 0,
        size: 20,
        status: 'ACTIVE',
      );

      expect(first.data, same(second.data));
      expect(
        first.data?.single.shortDescription,
        'Muc kho size lon cho don si',
      );
      expect(apiClient.getCallCount('/api/products'), 1);
    });

    test(
      'keeps distinct product list filters as separate cache entries',
      () async {
        final apiClient = _FakeApiClient();
        final repository = ProductRemoteRepository(apiClient: apiClient);

        await repository.getProducts(page: 0, size: 20, status: 'ACTIVE');
        await repository.getProducts(
          page: 0,
          size: 20,
          query: 'tom kho',
          status: 'ACTIVE',
        );

        expect(apiClient.getCallCount('/api/products'), 2);
      },
    );

    test('reuses product detail responses in memory', () async {
      final apiClient = _FakeApiClient();
      final repository = ProductRemoteRepository(apiClient: apiClient);

      final first = await repository.getProductDetail('prod-001');
      final second = await repository.getProductDetail('prod-001');

      expect(first.data, same(second.data));
      expect(apiClient.getCallCount('/api/products/prod-001'), 1);
    });

    test('reuses category tree responses in memory', () async {
      final apiClient = _FakeApiClient();
      final repository = ProductRemoteRepository(apiClient: apiClient);

      final first = await repository.getCategories();
      final second = await repository.getCategories();

      expect(first.data, same(second.data));
      expect(first.data?.single.name, 'Cá');
      expect(first.data?.single.children.single.name, 'Cá khô');
      expect(first.data?.single.children.single.parentId, 'cat-fish');
      expect(apiClient.getCallCount('/api/products/categories'), 1);
    });
  });
}

class _FakeApiClient implements ApiClient {
  final Map<String, int> _getCallCounts = {};

  @override
  final SecureTokenStorage tokenStorage = SecureTokenStorage();

  int getCallCount(String path) => _getCallCounts[path] ?? 0;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    _getCallCounts[path] = getCallCount(path) + 1;
    return ApiResponse<T>(
      success: true,
      message: 'OK',
      data: fromJson(_payloadFor(path)),
    );
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    required T Function(dynamic json) fromJson,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic json) fromJson,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String path) {
    throw UnimplementedError();
  }

  dynamic _payloadFor(String path) {
    if (path == '/api/products') {
      return [
        {
          'id': 'prod-001',
          'name': 'Muc kho loai 1',
          'slug': 'muc-kho-loai-1',
          'shortDescription': 'Muc kho size lon cho don si',
          'basePrice': 100000,
          'unit': 'kg',
          'minOrderQuantity': 2,
          'stockQuantity': 10,
          'status': 'ACTIVE',
          'isFeatured': true,
        },
      ];
    }
    if (path == '/api/products/categories') {
      return [
        {
          'id': 'cat-fish',
          'name': 'Cá',
          'children': [
            {
              'id': 'cat-003',
              'name': 'Cá khô',
              'parentId': 'cat-fish',
              'parentName': 'Cá',
              'children': [],
            },
          ],
        },
      ];
    }
    return {
      'id': 'prod-001',
      'name': 'Muc kho loai 1',
      'slug': 'muc-kho-loai-1',
      'shortDescription': 'Muc kho size lon cho don si',
      'basePrice': 100000,
      'unit': 'kg',
      'minOrderQuantity': 2,
      'stockQuantity': 10,
      'status': 'ACTIVE',
      'isFeatured': true,
      'description': 'Test product',
      'images': [],
      'priceTiers': [],
    };
  }
}
