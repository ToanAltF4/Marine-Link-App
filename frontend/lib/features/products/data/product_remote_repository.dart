import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_dto.dart';

class ProductRemoteRepository implements ProductRepository {
  final ApiClient apiClient;
  final Map<String, ApiResponse<List<Product>>> _productListCache = {};
  final Map<String, ApiResponse<ProductDetail>> _productDetailCache = {};

  ProductRemoteRepository({required this.apiClient});

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
    final queryParameters = _productListQueryParameters(
      page: page,
      size: size,
      query: query,
      categoryId: categoryId,
      featured: featured,
      status: status,
      sort: sort,
    );
    final cacheKey = _cacheKey(ApiEndpoints.products, queryParameters);
    final cached = _productListCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final response = await apiClient.get<List<Product>>(
      ApiEndpoints.products,
      queryParameters: queryParameters,
      fromJson: productListFromJson,
    );
    if (response.success && response.data != null) {
      _productListCache[cacheKey] = response;
    }
    return response;
  }

  @override
  Future<ApiResponse<ProductDetail>> getProductDetail(String productId) async {
    final path = ApiEndpoints.productDetail(productId);
    final cached = _productDetailCache[path];
    if (cached != null) {
      return cached;
    }

    final response = await apiClient.get<ProductDetail>(
      path,
      fromJson: productDetailFromJson,
    );
    if (response.success && response.data != null) {
      _productDetailCache[path] = response;
    }
    return response;
  }

  Map<String, dynamic> _productListQueryParameters({
    required int page,
    required int size,
    String? query,
    String? categoryId,
    bool? featured,
    String? status,
    String? sort,
  }) {
    final trimmedQuery = query?.trim();
    return {
      'page': page,
      'size': size,
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) 'q': trimmedQuery,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      'featured': ?featured,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };
  }

  String _cacheKey(String path, Map<String, dynamic> queryParameters) {
    final sortedKeys = queryParameters.keys.toList()..sort();
    final query = sortedKeys
        .map(
          (key) =>
              '$key=${Uri.encodeQueryComponent('${queryParameters[key]}')}',
        )
        .join('&');
    return query.isEmpty ? path : '$path?$query';
  }
}
